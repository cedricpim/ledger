module Ledger
  # Module including all the method for creating the table, column and rows
  # used to display the information requested.
  module ReportBuilder
    include CommandLineReporter

    private

    def title(title, options = {})
      header(CONFIG.output(:title).merge(title: title).merge(options))
    end

    def main_header(from:)
      add_row(CONFIG.output(from, :header), CONFIG.output(from, :options), CONFIG.color(:header))
    end

    def print(list)
      list.each { |elements| add_row(elements, CONFIG.color(:element)) }
    end

    def add_row(list, column_options = [], **row_options)
      return unless list

      row(row_options) do
        list.each_with_index { |v, i| column(v, column_options.fetch(i, {})) }
      end
    end

    def total_period_row(with_period:)
      return unless with_period

      row(CONFIG.color(:header)) do
        repository.currencies.each do |currency|
          %i[income expense].each { |type| column(*total.for(method: type, currency: currency)) }
        end

        column(*total.period_percentage)
      end
    end

    def total_current_row(with_period:)
      row(CONFIG.color(:header)) do
        repository.currencies.each do |currency|
          column(MoneyHelper.display(repository.current.exchange_to(currency)), CONFIG.output(:totals, :total))
        end

        column(*total.total_percentage) if with_period
      end
    end

    def balance_row(account, total)
      options = CONFIG.output(:balance, :options)

      row(CONFIG.color(:element)) do
        column(account, options[0])
        column(*MoneyHelper.display_with_color(total, options[1]))
      end
    end

    def total
      @total ||= Totals.new(repository)
    end
  end
end
