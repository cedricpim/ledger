module Ledger
  # Class representing the net worth on a given date. It also contains some
  # methods related to print the information to different sources.
  Networth = Struct.new(:date, :invested, :investment, :amount, :currency, keyword_init: true) do
    include Modules::HasDate
    include Modules::HasMoney
    include Modules::HasValidations

    def calculate_invested!(transactions)
      self.day_investment = nil
      self.invested = transactions.sum do |transaction|
        transaction.investment? && transaction.date == date ? transaction.exchange_to(currency).money : 0
      end.abs.to_s
    end

    def valid?
      parsed_date && money && valuation && day_investment
    end
  end
end
