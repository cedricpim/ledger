# Module containing helpers to deal with Money instances.
module MoneyHelper
  class << self
    def display(money)
      return '-' * 10 unless money.is_a?(Money)

      money.format(CONFIG.money_format)
    end
  end
end
