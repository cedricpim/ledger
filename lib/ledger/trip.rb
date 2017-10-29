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

  def to_s(options)
    options[:detailed] ? details : summary
  end

  def footer
    format(templates[:totals], totals: totals)
  end

  private

  def details
    transactions.map { |transaction| format(templates[:detailed], transaction.attributes) }
  end

  def summary
    transactions.group_by(&:account).flat_map do |account, gts|
      display_per_category(account, gts)
    end
  end

  def display_per_category(account, transactions)
    transactions.group_by(&:category).map do |category, cts|
      money = cts.sum(&:money)
      percentage = percentage(money, total_amounts[account])
      money = MoneyHelper.display(money)

      format(templates[:summary], account: account, category: category, money: money, percentage: percentage)
    end
  end

  def percentage(money, total)
    return 100.0 if total.zero?

    ((money.abs / total.abs) * 100).to_f.round(2)
  end

  def total_amounts
    @total_amounts ||= transactions.group_by(&:account).each_with_object({}) do |(account, ats), result|
      result[account] = ats.sum(&:money)
    end
  end

  def totals
    total_amounts.map do |account, money|
      format(templates[:account_total], account: account, money: MoneyHelper.display(money))
    end.join(' | ')
  end

  def templates
    @templates ||= CONFIGS.dig(:format, :trip)
  end
end
