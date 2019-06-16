module Ledger
  # Class representing a single transaction, it contains also some methods
  # related to printing the information to different sources.
  # The class is modeled by the fields defined on the configuration file.
  Transaction = Struct.new(*CONFIG.transaction_fields, keyword_init: true) do
    include Modules::HasDate
    include Modules::HasMoney
    include Modules::HasValidations

    # Number of shares by default
    DEFAULT_SHARES = 1
    # Separator for ISIN and number of shares
    SEPARATOR = ' - '.freeze

    def isin
      return unless Filters::Investment.new.call(self)

      description.split(SEPARATOR).first
    end

    def shares
      return 0 unless Filters::Investment.new.call(self)

      _, shares = description.split(SEPARATOR)
      (shares || DEFAULT_SHARES).to_i
    end

    def valid?
      parsed_date && money && (account && !account.empty?) && (category && !category.empty?)
    end
  end
end
