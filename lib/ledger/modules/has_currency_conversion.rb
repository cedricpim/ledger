module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for holding behaviour regarding classes that convert
    # the elements of the list to a given currency.
    module HasCurrencyConversion
      private

      def exchanged_list
        @exchanged_list = list.map { |elem| currency ? elem.exchange_to(currency) : elem }
      end

      def currency
        options[:currency]
      end
    end
  end
end
