module ItemAnalysisModule

  def merchants_with_high_item_count_hash
    merchant_hash(@item_repo).find_all do |key, value|
      merchant = per_merchant_standard_deviation(@item_repo)
      average = average_items_invoices_per_merchant(@item_repo)
      value.length >= merchant + average
    end.to_h
  end

  def merchants_with_high_item_count
    merchants_with_high_item_count_hash.keys
  end

  def golden_items
    dev = calculate_std_dev_for_items
    @item_repo.all.find_all do |item|
      item.unit_price >= dev*2
    end
  end

  def merchants_with_only_one_item
    items_by_merchant = merchant_hash(@item_repo)
    found = items_by_merchant.find_all do |merchant,items|
      items.length == 1
    end
    found.map do |pair|
      pair[0]
    end
  end

  def merchants_with_only_one_item_registered_in_month(month_name)
    merchants_with_only_one_item.find_all do |merchant|
      merchant.created_at.month == Time.parse(month_name).month
    end
  end

  def most_sold_item_for_merchant(merchant_id)
    valid_invoices = find_valid_invoices_by_merchant(merchant_id)
    invoice_items = map_invoice_to_invoice_items(valid_invoices).flatten
    grouped_by_item_id = invoice_items.group_by do |invoice|
      invoice.item_id
    end
    sorted = group_item_id_by_quantity(grouped_by_item_id)
    final = sort_pairs_by_quantity(sorted)
    final.map do |element|
      @item_repo.find_by_id(element[0])
    end
  end

  def group_item_id_by_quantity(grouped_by_item_id)
    item_quantity_array = grouped_by_item_id.map do |key, value|
      total = value.reduce(0) do |sum, invoice_item|
          sum + invoice_item.quantity
      end
      [key, total]
    end
    item_quantity_array.sort_by do |pair|
      pair[1]
    end
  end

  def sort_pairs_by_quantity(sorted)
    sorted.find_all do |pairs|
      pairs[1] == sorted[-1][1]
    end
  end
end
