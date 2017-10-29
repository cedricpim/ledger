# Module containing helpers to deal with Money instances.
module MoneyHelper
  class << self
    def display(money)
      money.format(CONFIGS.dig(:format, :fields, :money, :display))
    end
  end
end
