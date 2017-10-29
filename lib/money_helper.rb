# Module containing helpers to deal with Money instances.
module MoneyHelper
  class << self
    def display(money)
      color = CONFIGS.dig(:format, :colors, :money, money.negative? ? :negative : :positive)

      money.format(CONFIGS.dig(:format, :fields, :money, :display)).colorize(color)
    end
  end
end
