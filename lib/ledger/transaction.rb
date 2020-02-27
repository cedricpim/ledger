module Ledger
  # Class representing a single transaction, it contains also some methods
  # related to printing the information to different sources.
  # The class is modeled by the fields defined on the configuration file.
  Transaction = Struct.new(
    :account, :date, :category, :description, :quantity, :venue, :amount, :currency, :trip, :id, keyword_init: true
  ) do
    include Modules::HasDate
    include Modules::HasMoney
    include Modules::HasValidations

    def valid?
      parsed_date && money && (account && !account.empty?) && (category && !category.empty?)
    end
  end
end
