module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based if it is an investment.
    class Investment < Base
      def call(entry)
        CONFIG.investments.any? { |c| c.casecmp(entry.category).zero? }
      end
    end
  end
end
