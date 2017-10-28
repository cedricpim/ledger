# Class holding the transactions read from the ledger and used to query the
# content of the ledger.
class Content
  attr_reader :transactions

  alias list transactions

  def initialize(transactions)
    @transactions = transactions
  end

  def accounts
    transactions.group_by(&:account).map { |account, ats| Account.new(account, ats) }
  end

  def categories
    collect_values(:category)
  end

  def descriptions
    collect_values(:description)
  end

  def currencies
    collect_values(:currency)
  end

  def travels
    collect_values(:travel)
  end

  def trips
    transactions.select(&:travel).group_by(&:travel).map do |t, trs|
      Trip.new(t, trs)
    end
  end

  def report(options)
    filters = [
      from(options),
      till(options),
      exclude(options),
      monthly(options),
      annual(options)
    ].compact

    transactions.select { |t| filters.all? { |f| f.call(t) } }.group_by(&:account).map do |a, trs|
      Report.new(a, trs)
    end
  end

  def accounts_currency
    @accounts_currency ||= accounts.each_with_object({}) do |account, result|
      result[account] = transactions.find { |t| t.account == account }&.currency
    end
  end

  private

  def collect_values(key)
    transactions.map(&key).uniq.compact.sort
  end

  def from(options)
    return unless options[:from]

    ->(transaction) { transaction.parsed_date >= options[:from] }
  end

  def till(options)
    return unless options[:till]

    ->(transaction) { transaction.parsed_date <= options[:till] }
  end

  def exclude(options)
    return unless options[:exclude]

    ->(transaction) { !options[:exclude].include?(transaction.category) }
  end

  def monthly(options)
    return unless options[:monthly]

    ->(transaction) { transaction.parsed_date.month == options[:monthly] }
  end

  def annual(options)
    return unless options[:annual]

    ->(transaction) { transaction.parsed_date.cwyear == options[:annual] }
  end
end
