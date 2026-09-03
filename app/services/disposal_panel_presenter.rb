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
    frequency = waste_category.collection_frequency
    {
      chip: waste_category.chip_label,
      category_name: waste_category.name,
      blurb: waste_category.blurb,
      cost: fee.label,
      stat: frequency.present? ? { k: "Collected", v: frequency } : nil,
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
end
