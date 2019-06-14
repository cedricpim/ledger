module Ledger
  module Reports
    # Class responsible for generating the table with the balances of each
    # account.
    class Balance < Base
      def data
        @data ||= transactions.keys.map { |account| balance(account) }
      end

      private

      def filters
        [
          Filters::Period.new(options.merge(till: options[:date]))
        ]
      end

      def transactions
        @transactions ||= super.group_by(&:account).sort.to_h
      end

      def balance(account)
        {title: account, value: sum(account)}
      end

      def sum(account)
        total = transactions[account].sum { |transaction| transaction.exchange_to(currency_for[account]).money }

        return unless options[:all] || total.nonzero?

        total
      end
    end
  end
end
