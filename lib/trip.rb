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
    total = total_amounts.map { |account, money| "[#{account}] #{money.format(CONFIGS[:money][:display])}" }
    "Total: #{total.join(' | ')}"
  end

  def to_s(options)
    options[:summary] ? summary : details
  end

  private

  def total_amounts
    @total_amounts ||= transactions.group_by(&:account).each_with_object({}) do |(account, ats), result|
      result[account] = ats.sum(&:money)
    end
  end

  def summary
    transactions.group_by(&:account).flat_map do |account, gts|
      display_per_category(account, gts)
    end
  end

  def details
    transactions.map { |transaction| transaction.to_s(display_travel: false) }
  end

  def display_per_category(account, transactions)
    transactions.group_by(&:category).map do |category, cts|
      money = cts.sum(&:money)
      percentage = percentage(money, total_amounts[account])

      "[#{account}] #{category}: #{money.format(CONFIGS[:money][:display])} (#{percentage}%)"
    end
  end

  def percentage(money, total)
    return 100.0 if total.zero?

    ((money.abs / total.abs) * 100).to_f.round(2)
  end
end
