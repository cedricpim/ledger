module Ledger
  # Class holding the networth entries read from the networth file and used to
  # query it.
  class History
    include Modules::HasDateFiltering
    include Modules::HasDateSorting
    include Modules::HasCurrencyConversion

    alias networth_entries list

    def filtered_networth
      @filtered_networth ||= exchanged_list.select { |t| t.parsed_date.between?(*period) }
    end
  end
end
