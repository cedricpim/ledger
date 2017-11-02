# Module containing helpers to deal with Money instances.
module MoneyHelper
  class << self
    def display(money)
      return '-' * 10 unless money.is_a?(Money)

      money.format(CONFIG.money_format)
    end

    def percentage(value, transactions = [], &block)
      value, total = percentage_values(value, transactions, &block)

      return '-' * 5 unless total.is_a?(Money) && value.is_a?(Money)

      ((value.abs / total.abs) * 100).to_f.round(2)
    end

    private

    def percentage_values(value, transactions)
      return unless value.is_a?(Money)

      return yield(value) if block_given?

      filter = value.negative? ? :select : :reject
      [value, transactions.public_send(filter, &:expense?).sum(&:money)]
    end
  end
end
