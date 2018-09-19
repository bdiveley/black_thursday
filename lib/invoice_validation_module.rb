module InvoiceValidationModule

  def group_transaction_by_invoice(search_invoice_id)
    @transaction_repo.all.find_all do |transaction|
      transaction.invoice_id == search_invoice_id
    end
  end

  def find_valid_invoices_by_merchant(search_merchant_id)
    paid_invoices = @invoice_repo.all.find_all do |invoice|
      invoice_paid_in_full?(invoice.id)
    end
    paid_invoices.find_all do |invoice|
      invoice.merchant_id == search_merchant_id
    end
  end

  def invoice_paid_in_full?(search_invoice_id)
    trans_id_list = group_transaction_by_invoice(search_invoice_id)
    return false if trans_id_list == []
    if trans_id_list != []
      trans_id_list.any? do |trans|
        trans.result == :success
      end
    end
  end

  def invoice_pending?(search_invoice_id)
    trans_id_list = group_transaction_by_invoice(search_invoice_id)
    return true if trans_id_list == []
    if trans_id_list != []
      trans_id_list.all? do |trans|
        trans.result == :failed
      end
    end
  end
end
