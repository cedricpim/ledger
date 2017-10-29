# Class holding the transactions read from the ledger and used to query the
# content of the ledger.
class Content
  attr_reader :transactions

  alias list transactions

  def initialize(transactions)
    @transactions = transactions
  end

  def trips
    transactions.select(&:travel).group_by(&:travel).map do |t, trs|
      Trip.new(t, trs)
    end
  end

  def report(options)
    transactions.select { |t| filters(options).all? { |f| f.call(t) } }.group_by(&:account).map do |a, trs|
      Report.new(a, trs, transactions)
    end
  end

  def accounts_currency
    @accounts_currency ||= accounts.each_with_object({}) do |account, result|
      result[account] = transactions.find { |t| t.account == account }&.currency
    end
  end

  private

  def filters(options)
    [
      include_accounts(options),
      from(options),
      till(options),
      exclude(options),
      monthly(options),
      annual(options)
    ].compact
  end

  def include_accounts(options)
    return unless options[:accounts]

    ->(transaction) { options[:accounts].include?(transaction.account) }
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
