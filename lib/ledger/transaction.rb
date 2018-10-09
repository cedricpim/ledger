module Ledger
  # Class representing a single transaction, it contains also some methods
  # related to printing the information to different sources.
  # The class is modeled by the fields defined on the configuration file.
  Transaction = Struct.new(*CONFIG.transaction_fields, keyword_init: true) do
    include Modules::HasDate
    include Modules::HasMoney

    # Number of shares by default
    DEFAULT_SHARES = 1
    # Separator for ISIN and number of shares
    SEPARATOR = ' - '.freeze

    def investment?
      CONFIG.investments.any? { |c| c.casecmp(category).zero? }
    end

    def isin
      return unless investment?

      description.split(SEPARATOR).first
    end

    def shares
      return 0 unless investment?

      _, shares = description.split(SEPARATOR)
      (shares || DEFAULT_SHARES).to_i
    end
  end
end
