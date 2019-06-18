module Ledger
  module Printers
    # Class responsible for printing the table with the balance of each
    # account.
    class Balance < Base
      TITLE = 'Balance'.freeze

      # Receives data to be formatted in the following structure:
      # [{title: Account, value: Money}, {title: Account, value: nil}, ...]
      def call(data)
        title(TITLE)

        table do
          main_header(from: :balance)

          data.map { |info| line(info) }.each { |line| add_row(line) if line }
        end

        total.call
      end

      private

      def line(info)
        return unless info[:value]

        info.each_pair.with_index.map do |(key, value), index|
          options = CONFIG.output(:balance, :options)[index]

          key == :title ? [value, options] : MoneyHelper.display_with_color(value, options)
        end
      end
    end
  end
end
