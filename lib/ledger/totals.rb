module Ledger
  # Class responsible for containing all the information related to the total
  # values displayed about the transactions
  class Totals
    attr_reader :transactions, :exclusions, :currency, :current

    def initialize(repository)
      @transactions = repository.filtered_transactions
      @exclusions = repository.excluded_transactions
      @currency = repository.currencies.first
      @current = repository.current.exchange_to(currency)
    end

    def for(method:, currency:)
      value = public_send(method).exchange_to(currency)
      [
        MoneyHelper.display(value)[1..-1],
        MoneyHelper.color(value).merge(CONFIG.output(:totals, method))
      ]
    end

    def income
      @income ||= calculate(:income?, :expense?)
    end

    def expense
      @expense ||= calculate(:expense?, :income?)
    end

    def period_percentage
      percentage = income.zero? ? -100 : ((1 + (expense / income)) * 100).round(2)
      display_percentage(percentage, :period)
    end

    def total_percentage
      period = income - expense.abs
      percentage = (period / (current - period) * 100).round(2)
      display_percentage(percentage, :total)
    end

    private

    def calculate(transaction_method, exclusion_method)
      transactions.select(&transaction_method).sum { |t| t.exchange_to(currency).money } +
        exclusions.select(&exclusion_method).sum { |a| a.exchange_to(currency).money }
    end

    def display_percentage(value, key)
      ["#{value}%", MoneyHelper.color(value).merge(CONFIG.output(:totals, :percentage, key))]
    end
  end
end
