module Ledger
  # Class holding the transactions read from the ledger, retrieving the
  # investments and checking the current networth.
  class NetworthCalculation
    attr_reader :investments, :current, :currency

    def initialize(transactions, current, currency)
      @investments = transactions.select(&:investment?).map { |transaction| transaction.exchange_to(currency) }
      @current = current
      @currency = currency
    end

    def networth
      Networth.new(date: Date.today.to_s, investment: investment.to_s, amount: amount.to_s, currency: currency).tap do |worth|
        worth.valuations = valuations
        worth.calculate_invested!(investments)
      end
    end

    private

    def amount
      cash + investment
    end

    def cash
      current.exchange_to(currency)
    end

    def investment
      valuations.values.sum
    end

    def valuations
      investments_with_shares.each_with_object({}) do |(isin, shares), res|
        title, quote = quotes[isin]
        res[title || isin] = quote * shares
      end
    end

    def quotes
      @quotes ||= investments_with_shares.keys.map.with_object({}) do |isin, res|
        api = API::JustETF.new(isin: isin)
        res[isin] = [api.title, api.quote.exchange_to(currency)]
      end
    end

    def investments_with_shares
      @investments_with_shares ||= investments.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |t, res|
        res[t.isin] += t.shares
      end
    end
  end
end
