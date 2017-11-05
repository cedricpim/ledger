module Ledger
  # Module including all the method for creating the table, column and rows
  # used to display the information requested.
  module ReportBuilder
    include CommandLineReporter

    TITLE = {width: 70, align: 'center', rule: true, color: :cyan, bold: true}.freeze

    HEADER = {
      transaction: {
        list: %w[Date Category Amount Trip]
      },
      report: {
        summary: %w[Category Outflow (%) Inflow (%)],
        detailed: %w[Date Category Amount (%)]
      },
      trips: {
        summary: %w[Category Amount (%)],
        detailed: %w[Account Date Category Amount (%)]
      }
    }.freeze

    HEADER_OPTIONS = {
      transaction: {
        list: [{width: 15}, {width: 20}, {width: 15, align: 'center'}, {width: 15, align: 'center'}]
      },
      report: {
        summary: [
          {width: 20},
          {width: 15, align: 'center'}, {width: 7, align: 'center'},
          {width: 15, align: 'center'}, {width: 7, align: 'center'}
        ],
        detailed: [{width: 15}, {width: 20}, {width: 15, align: 'center'}, {width: 7, align: 'center'}]
      },
      trips: {
        summary: [{width: 20}, {width: 20, align: 'center'}, {width: 10, align: 'center'}],
        detailed: [{width: 10}, {width: 15}, {width: 20}, {width: 15, align: 'center'}, {width: 7, align: 'center'}]
      }
    }.freeze

    private

    def title(title)
      header(TITLE.merge(title: title))
    end

    def main_header(of:, type:)
      add_row(HEADER[of][type], HEADER_OPTIONS[of][type], color: :blue, bold: true)
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

    def footer(report)
      total = yield(report.total_filtered)
      month = yield(report.monthly)

      add_row(total, color: :yellow)
      add_row(month, color: :magenta)
    end

    def totals
      title('Totals')

      table do
        row(color: :blue, bold: true) do
          repository.currencies.each_key { |k| column(k.name, width: 23, align: 'center') }
        end
        row(color: :white) do
          repository.currencies.each_value { |v| column(v, align: 'center') }
        end
      end
    end
  end
end
