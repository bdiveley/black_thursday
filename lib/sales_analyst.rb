require_relative '../lib/std_dev_module'
require_relative '../lib/average_module'
require_relative '../lib/revenue_module'
require_relative '../lib/invoice_validation_module'
require_relative '../lib/item_analysis_module'
require 'Date'

class SalesAnalyst
  include StdDevModule
  include AverageModule
  include RevenueModule
  include InvoiceValidationModule
  include ItemAnalysisModule

  attr_reader :item_repo,
              :merchant_repo,
              :invoice_repo,
              :invoice_item_repo,
              :transaction_repo,
              :customer_repo

  def initialize(args)
    @item_repo = args[:items]
    @merchant_repo = args[:merchants]
    @invoice_repo = args[:invoices]
    @invoice_item_repo = args[:invoice_items]
    @transaction_repo = args[:transactions]
    @customer_repo = args[:customers]
  end

  def merchant_hash(repo)
    return_hash = {}
    @merchant_repo.all.each do |merchant|
      return_hash[merchant] = repo.all.find_all do |element|
        merchant.id == element.merchant_id
      end
    end
    return_hash
  end

  def top_merchants_by_invoice_count
    dev = per_merchant_standard_deviation(@invoice_repo)
    merchant_hash(@invoice_repo).find_all do |key, value|
      value.length >= dev*2 + average_items_invoices_per_merchant(@invoice_repo)
    end.to_h.keys
  end

  def bottom_merchants_by_invoice_count
    dev = per_merchant_standard_deviation(@invoice_repo)
    merchant_hash(@invoice_repo).find_all do |key, value|
      value.length <= average_items_invoices_per_merchant(@invoice_repo) - dev*2
    end.to_h.keys
  end

  def top_days_by_invoice_count
    average = @invoice_repo.all.count/7
    grouped_by_weekday = @invoice_repo.all.group_by do |invoice|
      invoice.created_at.wday
    end
    invoices_by_day = grouped_by_weekday.values.map do |invoice_collection|
      invoice_collection.count
    end
    day_nums = grouped_by_weekday.find_all do |weekday, invoices|
      invoices.count >= average + standard_deviation(invoices_by_day)
    end.to_h.keys
    day_nums.map do |daynumber|
      Date::DAYNAMES[daynumber]
    end
  end

  def invoice_status(status_sym)
    status = status_sym
    grouped_by_status = @invoice_repo.all.group_by do |invoice|
      invoice.status
    end
    (((grouped_by_status[status].count.to_f)/(@invoice_repo.all.count)) * 100).round(2)
  end

  def invoice_total(search_invoice_id)
    invoices_list = @invoice_item_repo.all.find_all do |i|
      i.invoice_id == search_invoice_id
    end
    invoices_list.reduce(BigDecimal(0,10)) do |sum, i|
      (i.quantity * i.unit_price) + sum
    end
  end

  def merchants_with_pending_invoices
    hash = merchant_hash(@invoice_repo)
    pending_merchants = hash.find_all do |merchant, invoices|
      invoices.any? do |invoice|
        invoice_pending?(invoice.id)
      end
    end
    pending_merchants.map do |merchant|
      merchant[0]
    end
  end

  def map_invoice_to_invoice_items(invoices)
    invoices.map do |invoice|
      @invoice_item_repo.all.find_all do |i|
        i.invoice_id == invoice.id
      end
    end
  end
end
