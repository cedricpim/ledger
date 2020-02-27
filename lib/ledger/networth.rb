module Ledger
  # Class representing the net worth on a given date. It also contains some
  # methods related to print the information to different sources.
  Networth = Struct.new(:date, :invested, :investment, :amount, :currency, :id, keyword_init: true) do
    include Modules::HasDate
    include Modules::HasMoney
    include Modules::HasValidations

    def valid?
      parsed_date && money && valuation && day_investment
    end
  end
end
