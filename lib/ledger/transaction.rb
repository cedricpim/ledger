module Ledger
  # Class representing a single transaction, it contains also some methods
  # related to printing the information to different sources.
  # The class is modeled by the fields defined on the configuration file.
  Transaction = Struct.new(*CONFIG.transaction_fields, keyword_init: true) do # rubocop:disable Metrics/BlockLength
    include Modules::HasDate
    include Modules::HasMoney
  end
end
