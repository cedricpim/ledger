module Ledger
  # Class holding the transactions read from the ledger, retrieving the
  # investments and checking the current networth.
  class NetworthCalculation
    attr_reader :investments, :current, :currency

    def initialize(transactions, current, currency)
      @investments = transactions.select(&:investment?)
      @current = current
      @currency = currency
    end

    def networth
      Networth.new(date: Date.today.to_s, amount: amount.to_s, currency: currency)
    end

    private

    def amount
      cash + evaluation
    end

    def cash
      current.exchange_to(currency)
    end

    def evaluation
      investments_with_shares.sum { |isin, shares| quotes[isin] * shares }
    end

    def quotes
      @quotes ||= investments_with_shares.keys.map.with_object({}) do |isin, res|
        res[isin] = API::JustETF.new(isin: isin).quote.exchange_to(currency)
      end
    end

    def investments_with_shares
      @investments_with_shares ||= investments.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |t, res|
        res[t.isin] += t.shares
      end
    end
  end
end
