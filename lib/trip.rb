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
    "Total: #{total_amounts.map { |account, money| "[#{account}] #{money.format(MONEY_DISPLAY_FORMAT)}" }.join(' | ')}"
  end

  def to_s(options)
    options[:summary] ? summary : details
  end

  private

  def total_amounts
    @total_amounts ||= transactions.group_by(&:account).map { |k, v| [k, v.sum(&:money)] }.to_h
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
      money = cts.sum(&:money)
      percentage = percentage(money, total_amounts[account])

      "[#{account}] #{category}: #{money.format(MONEY_DISPLAY_FORMAT)} (#{percentage}%)"
    end
  end

  def percentage(money, total)
    return 100.0 if total.zero?

    ((money.abs / total.abs) * 100).to_f.round(2)
  end
end
