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

    def add_balance_row(account, total)
      row_options = CONFIG.output(:balance, :options)
      values = [account, '', MoneyHelper.display(total)]

      add_row(values, colorize_money(row_options, total, 2), CONFIG.color(:element))
    end

    def colorize_money(options, total, index)
      money_options = options.delete_at(index)

      options.insert(index, money_options.merge(MoneyHelper.color(total)))
    end
  end
end
