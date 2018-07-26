module Ledger
  # Class responsible for representing all trips, it contains the global identifier
  # and all the transactions belonging to all the trips. It is capable of
  # listing the transactions and provide a summary of each trip.
  class GlobalTrip
    attr_reader :travel, :transactions, :total_transactions

    def initialize(travel, transactions, total_transactions)
      @travel = travel
      @transactions = transactions
      @total_transactions = total_transactions
    end

    def list
      list = transactions.group_by(&:travel).sort_by do |_travel, tts|
        tts.max_by(&:parsed_date).parsed_date
      end

      list.map { |travel, tts| [travel].concat(MoneyHelper.display_with_percentage(tts, transactions)) }
    end

    def total
      ['Total'].concat(MoneyHelper.display_with_percentage(transactions, total_transactions))
    end
  end
end
