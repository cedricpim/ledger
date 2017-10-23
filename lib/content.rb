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
    transactions.select(&:travel).group_by(&:travel).map { |t, trs| Trip.new(t, trs) }
  end

  def report(options)
    filters = []
    filters << ->(transaction) { transaction.parsed_date >= options[:from] } if options[:from]
    filters << ->(transaction) { transaction.parsed_date <= options[:till] } if options[:till]
    filters << ->(transaction) { !options[:exclude].include?(transaction.category) } if options[:exclude]
    filters << ->(transaction) { transaction.parsed_date.month == options[:monthly] } if options[:monthly]
    filters << ->(transaction) { transaction.parsed_date.cwyear == options[:annual] } if options[:annual]

    transactions.select { |t| filters.all? { |f| f.call(t) } }.group_by(&:account).map { |a, trs| Report.new(a, trs) }
  end

  def currency_per_account
    @currency_per_account ||= accounts.each_with_object({}) do |account, result|
      result[account] = transactions.find { |t| t.account == account }&.currency
    end
  end
end
