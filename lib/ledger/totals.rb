module Ledger
  # Class responsible for containing all the information related to the total
  # values displayed about the transactions
  class Totals
    attr_reader :transactions, :currency, :current

    def initialize(transactions, currency, current)
      @transactions = transactions
      @currency = currency
      @current = current.exchange_to(currency)
    end

    def for(method:, currency:)
      value = public_send(method).exchange_to(currency)
      [
        MoneyHelper.display(value)[1..-1],
        MoneyHelper.color(value).merge(CONFIG.output(:totals, method))
      ]
    end

    def income
      @income ||= transactions.reject(&:expense?).sum { |t| t.exchange_to(currency).money }
    end

    def expense
      @expense ||= transactions.select(&:expense?).sum { |t| t.exchange_to(currency).money }
    end

    # - how to handle excluded categories
    def period_percentage
      percentage = income.zero? ? -100 : ((1 + (expense / income)) * 100).round(2)
      ["#{percentage}%", MoneyHelper.color(percentage).merge(CONFIG.output(:totals, :percentage, :period))]
    end

    def total_percentage
      period = income - expense.abs
      percentage = (period / (current - period) * 100).round(2)
      ["#{percentage}%", MoneyHelper.color(percentage).merge(CONFIG.output(:totals, :percentage, :total))]
    end
  end
end
