# Class responsible for representing a trip, it contains the identifier of the
# trip (travel attribute) and all the transactions belonging to this trip. It
# is capable of listing the transactions and provide a summary of the
# transactions, grouped by account and category.
class Trip
  attr_reader :travel, :transactions

  def initialize(travel, transactions)
    @travel = travel
    @transactions = transactions
  end

  def totals
    totals = total_amounts.map { |k, v| "[#{k.code}] #{v.to_f}#{k.currency}" }
    "Total: #{totals.join(' | ')}"
  end

  def to_s(options)
    options[:summary] ? summary : details
  end

  private

  def total_amounts
    @total_amounts ||= transactions.group_by(&:account).map { |k, v| [k, v.sum(&:amount)] }.to_h
  end

  def summary
    transactions.group_by(&:account).flat_map do |account, gts|
      display_categories(account, gts)
    end
  end

  def details
    transactions.map { |transaction| transaction.to_s(display_travel: false) }
  end

  def display_categories(account, transactions)
    transactions.group_by(&:category).map do |category, cts|
      amount = cts.sum(&:amount)
      percentage = percentage(amount, total_amounts[account])

      "[#{account.code}] #{category}: #{amount.to_f}#{account.currency} (#{percentage}%)"
    end
  end

  def percentage(amount, total_amount)
    return 100.0 if total_amount.zero?

    ((amount.abs / total_amount.abs) * 100).to_f.round(2)
  end
end
