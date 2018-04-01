module Ledger
  # Class responsible for representing all trips, it contains the global identifier
  # and all the transactions belonging to all the trips. It is capable of
  # listing the transactions and provide a summary of each trip.
  class GlobalTrips
    attr_reader :travel, :transactions, :current, :currency

    def initialize(travel, transactions, current, currency)
      @travel = travel
      @transactions = transactions.map { |t| t.exchange_to(currency) }
      @current = current
      @currency = currency
    end

    def categories
      list = transactions.select(&:travel).group_by(&:travel).sort_by do |travel, tts|
        tts.sort_by(&:parsed_date).last.parsed_date
      end

      list.map do |travel, tts|
        money = tts.sum(&:money)

        [travel, MoneyHelper.display(money), MoneyHelper.percentage(money, transactions)]
      end
    end

    def total
      money = transactions.sum(&:money)
      percentage = MoneyHelper.percentage(money) { current.exchange_to(currency) }
      ['Total', MoneyHelper.display(money), percentage]
    end
  end
end
