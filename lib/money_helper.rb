# Module containing helpers to calculate balances from transactions and format
# money instance to be displayed.
module MoneyHelper
  class << self
    def display(money)
      money.format(CONFIGS.dig(:format, :fields, :money, :display))
    end

    def balance(transactions)
      expense = transactions.select(&:expense?).sum(&:money)
      income = transactions.reject(&:expense?).sum(&:money)

      [expense, income].reject(&:zero?).map do |value|
        formatted_value = MoneyHelper.display(value)

        block_given? ? yield(value, formatted_value) : formatted_value
      end.join(' | ')
    end
  end
end
