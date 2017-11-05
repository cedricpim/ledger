module Ledger
  # Module including all the method for creating the table, column and rows
  # used to display the information requested.
  module ReportBuilder
    include CommandLineReporter

    private

    def title(title)
      header(CONFIG.output(:title).merge(title: title))
    end

    def main_header(of:, type:)
      add_row(CONFIG.output(of, type, :header), CONFIG.output(of, type, :options), color: :blue, bold: true)
    end

    def print(list)
      list.each do |elements|
        values, options = block_given? ? yield(elements) : [elements, color: :white]

        add_row(values, options)
      end
    end

    def add_row(list, column_options = [], **row_options)
      row(row_options) do
        list.each_with_index { |v, i| column(v, column_options.fetch(i, {})) }
      end
    end
  end
end
