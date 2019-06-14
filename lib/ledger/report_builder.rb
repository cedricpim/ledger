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

    def add_colored_row(list, row_options = {})
      return unless list

      row(row_options) do
        list.each { |elem| column(*elem) }
      end
    end

    def add_row(list, column_options = [], **row_options)
      return unless list

      row(row_options) do
        list.each_with_index { |v, i| column(v, column_options.fetch(i, {})) }
      end
    end
  end
end
