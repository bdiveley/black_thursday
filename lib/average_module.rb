module AverageModule

  def average_items_invoices_per_merchant(repo)
    (repo.all.count.to_f / @merchant_repo.all.count).round(2)
  end

  def average_items_per_merchant
    average_items_invoices_per_merchant(@item_repo)
  end

  def average_invoices_per_merchant
    average_items_invoices_per_merchant(@invoice_repo)
  end

  def average_item_price_for_merchant(search_id)
    merchant_array = merchant_hash(@item_repo).find do |merchant, items|
      merchant.id == search_id
    end
    bd_array = merchant_array[1].map do |item|
      item.unit_price
    end
    (sum(bd_array) / bd_array.length).round(2)
  end

  def average_average_price_per_merchant
    array = []
    merchant_hash(@item_repo).each do |key, value|
      array << average_item_price_for_merchant(key.id)
    end
    (sum(array)/array.length).round(2)
  end

  def calculate_average_item_price
    prices = @item_repo.all.map do |item|
      item.unit_price
    end
    sum(prices)/@item_repo.all.length
  end
end
