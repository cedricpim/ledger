module Ledger
  # Class representing the net worth on a given date. It also contains some
  # methods related to print the information to different sources.
  Networth = Struct.new(:date, :amount, :currency, keyword_init: true) do
    include Modules::HasDate
    include Modules::HasMoney

    attr_accessor :valuation

    def list
      (balances + [other]).map do |elem|
        elem.tap { elem[1] = MoneyHelper.display(elem[1]) }
      end
    end

    def total
      ['Total', MoneyHelper.display(money), 100.0]
    end

    private

    def balances
      @balances ||= valuation.map { |title, value| [title, value, (value / money * 100).round(2)] }
    end

    def other
      @other ||= ['Other', calc(money, 1), calc(100, 2).round(2)]
    end

    def calc(total, index)
      total - balances.sum { |balance| balance[index] }
    end
  end
end
