# Builds the single "dispose" hash that both the item decision page
# (_decision_card) and the scan page (_disposal_card) render from, so the two
# surfaces always show the exact same disposal facts from the exact same logic.
#
#   DisposalPanelPresenter.call(item) # => Hash
#
# The item only needs to respond to waste_category_key / title / category — an
# unsaved Item.new is enough (DisposalFeeEstimator only reads accessors).

class DisposalPanelPresenter
  def self.call(item)
    waste_category = item.waste_category
    return empty_panel unless waste_category

    fee = DisposalFeeEstimator.call(item)
    {
      chip: waste_category.chip_label,
      category_name: waste_category.name,
      blurb: waste_category.blurb,
      cost: fee.label,
      stat: collected_stat(item, waste_category),
      facts: [["Category", waste_category.name], ["Cost", fee.label],
              ["Application", waste_category.application_required? ? "Required" : "Not required"]],
      steps: waste_category.steps,
      notes: fee.notes,
      apply_url: fee.application_url,
      apply_label: fee.application_label
    }
  end

  def self.empty_panel
    { chip: nil, category_name: nil, blurb: "Disposal category not yet determined for this item.",
      cost: nil, stat: nil, facts: [], steps: [], notes: [],
      apply_url: nil, apply_label: nil }
  end

  # The "Collected" stat: the actual upcoming pickup date for waste categories
  # with a fixed collection day (matching what the dashboard and schedule page
  # already show via Schedule.collected_on?), falling back to the category's
  # general frequency text (e.g. "Twice monthly") for everything else.
  def self.collected_stat(item, waste_category)
    next_date = Schedule.next_collection_date_for(item.waste_category_key)
    return { k: "Collected", v: next_date.strftime("%b %-d %a") } if next_date

    frequency = waste_category.collection_frequency
    { k: "Collected", v: frequency } if frequency.present?
  end
end
