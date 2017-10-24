# Class holding the transactions read from the ledger and used to query the
# content of the ledger.
class Content
  attr_reader :transactions

  def initialize(transactions)
    @transactions = transactions
  end

  def accounts
    transactions.map(&:account).uniq.sort
  end

  def categories
    transactions.map(&:category).uniq.sort
  end

  def descriptions
    transactions.map(&:description).uniq.compact.sort
  end

  def currencies
    transactions.map(&:currency).uniq.sort
  end

  def travels
    transactions.map(&:travel).uniq.compact.sort
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

  def currency_per_account
    @currency_per_account ||= accounts.each_with_object({}) do |account, result|
      result[account] = transactions.find { |t| t.account == account }&.currency
    end
  end

  private

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
