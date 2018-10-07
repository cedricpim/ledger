module Ledger
  # Class representing the net worth on a given date. It also contains some
  # methods related to print the information to different sources.
  Networth = Struct.new(:date, :amount, :currency, keyword_init: true) do
  end
end
