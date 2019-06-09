module Ledger
  # Class responsible for applying each of the received filters to the list of
  # entries given.
  class Filter
    attr_reader :entries, :filters

    def initialize(entries, filters:)
      @entries = entries
      @filter = filters
    end
  end
end
