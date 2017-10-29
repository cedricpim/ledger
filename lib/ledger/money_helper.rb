# Module containing helpers to deal with Money instances.
module MoneyHelper
  class << self
    def display(money)
      money
        .format(CONFIG.money_format)
        .colorize(CONFIG.money_color(type: money.negative? ? :negative : :positive))
    end
  end
end
