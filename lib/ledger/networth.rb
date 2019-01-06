module Ledger
  # Class representing the net worth on a given date. It also contains some
  # methods related to print the information to different sources.
  Networth = Struct.new(:date, :invested, :investment, :amount, :currency, keyword_init: true) do
    include Modules::HasDate
    include Modules::HasMoney

    attr_accessor :valuations

    def list
      (balances + [other]).map do |elem|
        elem.tap { elem[1] = MoneyHelper.display(elem[1]) }
      end
    end

    def total
      ['Total', MoneyHelper.display(money), 100.0]
    end

    def calculate_invested!(transactions)
      total = transactions.select(&:investment?).sum { |investment| investment.date == date ? investment.money.cents : 0 }.abs
      self.invested = Money.new(total, currency)
    end

    private

    def balances
      @balances ||= valuations.map { |title, value| [title, value, (value / money * 100).round(2)] }
    end

    def other
      @other ||= ['Other', calc(money, 1), calc(100, 2).round(2)]
    end

    def calc(total, index)
      total - balances.sum { |balance| balance[index] }
    end
  end
end
