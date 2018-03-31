module Ledger
  # Module including all the method for creating the table, column and rows
  # used to display the information requested.
  module ReportBuilder
    include CommandLineReporter

    private

    def title(title)
      header(CONFIG.output(:title).merge(title: title))
    end

    def main_header(of: nil, type: nil)
      keys = [of, type].compact

      add_row(CONFIG.output(*keys, :header), CONFIG.output(*keys, :options), CONFIG.color(:header))
    end

    def footer(entity)
      total = yield(entity.total) if entity.respond_to?(:total)
      period = yield(entity.period) if entity.respond_to?(:period)

      add_row(total, CONFIG.color(:total))
      add_row(period, CONFIG.color(:period))
    end

    def print(list)
      list.each do |elements|
        values, options = block_given? ? yield(elements) : [elements, CONFIG.color(:element)]

        add_row(values, options)
      end
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
        column(MoneyHelper.display(total), MoneyHelper.color(total).merge(options[1]))
      end
    end

    def total
      @total ||= Totals.new(repository)
    end
  end
end
