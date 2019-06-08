module Ledger
  # Class holding the transactions read from the ledger, retrieving the
  # investments and checking the current networth.
  class NetworthCalculation
    attr_reader :transactions, :currency

    def initialize(transactions, currency)
      @transactions = transactions
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
      current + investment
    end

    def current
      transactions.sum do |transaction|
        excluded_accounts.include?(transaction.account.downcase) ? 0 : transaction.exchange_to(currency).money
      end
    end

    def investment
      valuations.values.sum
    end

    def valuations
      @valuations ||= investments_with_shares.each_with_object({}) do |(isin, shares), res|
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
      @investments_with_shares ||= investments.each_with_object(Hash.new(0)) do |investment, res|
        res[investment.isin] += investment.shares
      end
    end

    def investments
      @investments ||= transactions.select(&:investment?)
    end

    def excluded_accounts
      @excluded_accounts ||= CONFIG.exclusions(of: :networth)[:accounts].map(&:downcase)
    end
  end
end
