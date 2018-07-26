module Ledger
  # Class responsible for containing all the information related to the total
  # values displayed about the transactions
  class Total
    attr_reader :transactions, :exclusions, :currency, :current

    def initialize(repository)
      @transactions = repository.filtered_transactions
      @exclusions = repository.excluded_transactions
      @currency = repository.currencies.first
      @current = currency ? repository.current.exchange_to(currency) : Money.new(0, currency)
    end

    def for(method:, currency:)
      value = send(method).exchange_to(currency)
      MoneyHelper.display_with_color(value, CONFIG.output(:totals, method))
    end

    def period_percentage
      calculate_percentage(income, expense, :period) { expense / income }
    end

    def total_percentage
      calculate_percentage(income, expense, :total) { |period| period / (current - period) }
    end

    private

    def income
      @income ||= begin
        value = calculate(:income?, :expense?)
        value.positive? ? value : Money.new(0, currency)
      end
    end

    def expense
      @expense ||= begin
        value = calculate(:expense?, :income?)
        value.negative? ? value : Money.new(0, currency)
      end
    end

    def calculate(transaction_method, exclusion_method)
      transactions.select(&transaction_method).sum { |t| t.exchange_to(currency).money } +
        exclusions.select(&exclusion_method).sum { |a| a.exchange_to(currency).money }
    end

    def calculate_percentage(income, expense, type)
      return display_percentage(expense / income, type) if income.zero?
      return display_percentage(income / expense, type) if expense.zero?

      period = income - expense.abs

      value = yield period

      percentage = (value * 100).round(2).abs * (period.positive? ? 1 : -1)

      display_percentage(percentage, type)
    end

    def display_percentage(value, key)
      value =
        case
        when value.nan?      then 0.0
        when value.infinite? then (value.negative? ? -100.0 : 100.0)
        else value
        end

      MoneyHelper.display_with_color(value, CONFIG.output(:totals, :percentage, key))
    end
  end
end
