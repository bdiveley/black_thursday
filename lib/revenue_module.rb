module RevenueModule

  def total_revenue_by_date(date)
    found_invoices = @invoice_repo.all.find_all do |invoice|
      invoice.created_at.strftime('%F') == date.strftime('%F')
    end
    invoice_totals = found_invoices.map do |invoice|
      invoice_total(invoice.id)
    end
    sum(invoice_totals)
  end

  def revenue_by_merchant(search_merchant_id)
    merchant_paid_invoices = find_valid_invoices_by_merchant(search_merchant_id)
    merchant_paid_invoices.reduce(0) do |sum, invoice|
      invoice_total(invoice.id) + sum
    end
  end

  def top_revenue_earners(number=20)
    merchants_ranked_by_revenue[0..(number-1)]
  end

  def merchants_ranked_by_revenue
    @merchant_repo.all.sort_by do |merchant|
      revenue_by_merchant(merchant.id)
    end.reverse
  end

  def best_item_for_merchant(merchant_id)
    valid = find_valid_invoices_by_merchant(merchant_id)
    invoice_items = map_invoice_to_invoice_items(valid).flatten!
    grouped = invoice_items.group_by do |invoice_item|
      invoice_item.item_id
    end
    winner = sort_pairs_by_revenue(grouped).last
    @item_repo.find_by_id(winner[0])
  end

  def group_item_id_by_revenue(grouped)
    grouped.map do |key, value|
      total = value.reduce(0) do |sum, invoice_item|
          sum + (invoice_item.quantity * invoice_item.unit_price)
      end
      [key, total]
    end
  end

  def sort_pairs_by_revenue(grouped)
    item_price_array = group_item_id_by_revenue(grouped)
    item_price_array.sort_by do |pair|
      pair[1]
    end
  end
end
