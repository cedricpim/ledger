module Ledger
  # Class responsible for representing all trips, it contains the global identifier
  # and all the transactions belonging to all the trips. It is capable of
  # listing the transactions and provide a summary of each trip.
  class GlobalTrips
    attr_reader :travel, :transactions, :total_transactions, :currency

    def initialize(travel, transactions, total_transactions, currency)
      @travel = travel
      @transactions = transactions.map { |t| t.exchange_to(currency) }
      @total_transactions = total_transactions.map { |t| t.exchange_to(currency) }
      @currency = currency
    end

    def list
      list = transactions.select(&:travel).group_by(&:travel).sort_by do |_travel, tts|
        tts.sort_by(&:parsed_date).last.parsed_date
      end

      list.map { |travel, tts| [travel].concat(MoneyHelper.display_with_percentage(tts, transactions)) }
    end

    def total
      ['Total'].concat(MoneyHelper.display_with_percentage(transactions, total_transactions))
    end
  end
end
