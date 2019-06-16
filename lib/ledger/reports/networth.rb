module Ledger
  module Reports
    # Class responsible for generating the table with the current networth.
    class Networth < Base
      TOTAL = 'Total'.freeze

      CASH = 'Cash'.freeze

      def data
        @data ||= if transactions.any?
          valuations.map { |title, value| statistics(title: title, value: value) } + [cash] + [total]
        else
          []
        end
      end

      def store(entry: nil)
        storage.data(entry)
      end

      private

      def cash
        statistics(title: CASH, value: current)
      end

      def total
        statistics(title: TOTAL, value: networth)
      end

      def statistics(title:, value:)
        {title: title, value: value, percentage: (value / networth * 100).round(2)}
      end

      def networth
        @networth ||= current + investment
      end

      def current
        @current ||= transactions.sum(&:money)
      end

      def investment
        @investment ||= valuations.values.sum
      end

      def valuations
        @valuations ||= investments_with_shares.each_with_object({}) do |(isin, shares), res|
          api = API::JustETF.new(isin: isin)
          res[api.title] = api.quote.exchange_to(currency) * shares
        end
      end

      def investments_with_shares
        investments.each_with_object(Hash.new(0)) { |investment, res| res[investment.isin] += investment.shares }
      end

      def investments
        @investments ||= Filter.new(transactions, filters: [Filters::Investment.new(options)]).call
      end

      def filters
        [
          Filters::IncludeCategory.new(options, :networth),
          Filters::IncludeAccount.new(options, :networth)
        ]
      end

      def storage
        @storage ||= Storage.new(options, ledger: ledger)
      end
    end
  end
end
