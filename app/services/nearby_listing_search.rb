require "net/http"

# Finds currently-live Jimoty listings similar to an item, near the user, and
# reduces them to a few numbers we can show on the item page.
#
#   NearbyListingSearch.call(item) # => Result
#
# Never raises: any network, parse or empty-result outcome returns an empty
# Result so item creation always succeeds.

class NearbyListingSearch
  BASE_HOST = "https://jmty.jp".freeze

  # Identify ourselves rather than pretending to be a browser. jmty's robots.txt
  # allows this (User-agent: * / Allow: /), verified 2026-08-30.
  USER_AGENT = "Tossibly/1.0 (student project; +https://github.com/dholmes-jp/tossibly)".freeze

  # Selectors verified against real jmty.jp markup on 2026-08-30. If this parser
  # ever returns zero listings for an obviously-common keyword, check these first
  # — the markup belongs to them and can change without notice.
  LISTING_SELECTOR = "li.p-articles-list-item".freeze
  TITLE_SELECTOR   = ".p-item-title a".freeze
  PRICE_SELECTOR   = ".p-item-most-important b".freeze
  CLOSED_SELECTOR  = ".p-item-close".freeze # only present on 受付終了 listings
  HEADING_SELECTOR = "h1.p-articles-title".freeze

  # Ward name as it appears in User#address => jmty area slug.
  WARD_SLUGS = {
    "meguro" => "a-265-meguro",
    "shinagawa" => "a-264-shinagawa",
    "ota" => "a-266-ota",
    "setagaya" => "a-267-setagaya",
    "shibuya" => "a-268-shibuya"
  }.freeze
  DEFAULT_WARD_SLUG = "a-265-meguro".freeze

  MIN_RESULTS      = 5   # stop widening once we have this many live listings
  TOTAL_BUDGET     = 5.0 # seconds for the whole ladder; Heroku kills requests at 30
  REQUEST_TIMEOUT  = 3   # seconds per request
  OUTLIER_MULTIPLE = 5   # drop paid listings above this multiple of the median

  Result = Struct.new(:total_active, :free_count, :paid_count, :typical,
                      :low, :high, :scope, :fetched_at, keyword_init: true) do
    def any?
      total_active.to_i.positive?
    end

    # Shaped for Item's store_accessor attributes.
    def to_item_attributes
      {
        nearby_count: total_active,
        free_count: free_count,
        typical_price: typical,
        price_low: low,
        price_high: high,
        search_scope: scope.to_s.presence,
        checked_at: fetched_at
      }
    end
  end

  def self.call(item)
    new(item).call
  end

  def initialize(item)
    @item = item
    @deadline = Time.current + TOTAL_BUDGET
  end

  def call
    return empty_result if keyword.blank?

    listings = fetch_active(ward_slug)
    scope = :ward

    # Widen the AREA before ever relaxing the keyword: keyword precision is what
    # keeps recycle-shop bundle listings out. Tight local searches often return
    # only expired listings, which is why this tier exists at all.
    if listings.size < MIN_RESULTS && time_left?
      tokyo = fetch_active(nil)
      if tokyo.size > listings.size
        listings = tokyo
        scope = :tokyo
      end
    end

    build_result(listings, scope)
  rescue StandardError => e
    Rails.logger.error("NearbyListingSearch failed: #{e.class}: #{e.message}")
    empty_result
  end

  private

  def keyword
    @keyword ||= @item.jimoty_search_keyword.to_s.strip
  end

  def ward_slug
    address = @item.user&.address.to_s.downcase
    _name, slug = WARD_SLUGS.find { |name, _| address.include?(name) }
    slug || DEFAULT_WARD_SLUG
  end

  def search_url(area_slug)
    path = area_slug ? "/tokyo/sale-all/g-all/#{area_slug}" : "/tokyo/sale"
    "#{BASE_HOST}#{path}?keyword=#{CGI.escape(keyword)}"
  end

  def fetch_active(area_slug)
    html = get(search_url(area_slug))
    return [] if html.blank?

    doc = Nokogiri::HTML(html)
    return [] unless keyword_applied?(doc)

    doc.css(LISTING_SELECTOR)
       .filter_map { |node| parse_listing(node) }
       .uniq { |listing| listing[:url] }
  end

  # One search-result node => { url:, price: }, or nil when it isn't a live
  # goods listing we can price.
  def parse_listing(node)
    return if node.at_css(CLOSED_SELECTOR) # 受付終了 — not a live listing

    href = node.at_css(TITLE_SELECTOR)&.[]("href").to_s
    return unless href.include?("/sale-") # skips job ads and other verticals

    price = parse_price(node.at_css(PRICE_SELECTOR)&.text)
    return if price.nil?

    { url: href, price: price }
  end

  def get(url)
    remaining = @deadline - Time.current
    return nil if remaining <= 0

    timeout = [REQUEST_TIMEOUT, remaining].min
    uri = URI.parse(url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                        open_timeout: timeout, read_timeout: timeout) do |http|
      response = http.get(uri.request_uri, "User-Agent" => USER_AGENT)
      response.is_a?(Net::HTTPSuccess) ? response.body : nil
    end
  rescue StandardError => e
    Rails.logger.warn("NearbyListingSearch fetch failed (#{url}): #{e.class}")
    nil
  end

  def parse_price(text)
    digits = text.to_s.gsub(/[^0-9]/, "")
    digits.presence&.to_i
  end

  # Guards against a page that ignored our keyword and returned everything.
  def keyword_applied?(doc)
    heading = doc.at_css(HEADING_SELECTOR)&.text.to_s
    return true if heading.include?(keyword)

    Rails.logger.warn("NearbyListingSearch: keyword #{keyword.inspect} missing from results heading; discarding page")
    false
  end

  def build_result(listings, scope)
    return empty_result if listings.empty?

    prices = listings.map { |listing| listing[:price] }
    free   = prices.count(&:zero?)
    # Free listings are counted separately, never folded into the median — a market
    # that's half giveaways would otherwise report a misleadingly low "typical" price.
    paid   = reject_outliers(prices.reject(&:zero?).sort)

    Result.new(
      total_active: listings.size,
      free_count: free,
      paid_count: paid.size,
      typical: median(paid),
      low: paid.first,
      high: paid.last,
      scope: scope,
      fetched_at: Time.current
    )
  end

  def reject_outliers(sorted)
    return sorted if sorted.size < 4

    middle = median(sorted)
    return sorted if middle.nil? || middle.zero?

    sorted.select { |price| price <= middle * OUTLIER_MULTIPLE }
  end

  def median(sorted)
    return nil if sorted.blank?

    mid = sorted.size / 2
    sorted.size.odd? ? sorted[mid] : ((sorted[mid - 1] + sorted[mid]) / 2.0).round
  end

  def time_left?
    Time.current < @deadline
  end

  def empty_result
    Result.new(total_active: 0, free_count: 0, paid_count: 0, scope: nil, fetched_at: Time.current)
  end
end
