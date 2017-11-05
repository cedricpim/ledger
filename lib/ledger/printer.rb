module Ledger
  # Class holding the logic to print whatever query was made to the console.
  # Very simple and straightforward, the idea is to just be able to display
  # the title/header the and the respective summary.
  class Printer
    include ReportBuilder

    attr_reader :repository, :options

    def initialize(options = {})
      @repository = Ledger::Repository.new
      @options = options
    end

    def list
      title('Transactions')

      table do
        main_header(of: :transaction, type: :list)

        print(repository.transactions) do |t|
          [t.details(include_travel: true)[0..-2], color: t.processed_color]
        end
      end

      totals
    end

    def report
      type = options[:detailed] ? :detailed : :summary

      repository.report(options).each do |report|
        title(report.account)

        table do
          main_header(of: :report, type: type)

          build_report(report, type)
        end
      end

      totals
    end

    def trips
      type = options[:detailed] ? :detailed : :summary

      repository.trips(options).each do |trip|
        title(trip.travel)

        table do
          main_header(of: :trips, type: type)

          build_trip(trip, type)
        end
      end

      totals
    end

    private

    def build_trip(trip, type)
      if type == :detailed
        print(trip.transactions) do |t|
          values = t.details(percentage_related_to: trip.transactions).unshift(t.account)

          [values, color: t.processed_color]
        end
      else
        print(trip.categories)
      end

      add_row(trip.total(type), color: :yellow)
    end

    def build_report(report, type)
      if type == :detailed
        print(report.filtered_transactions) { |t| [t.details, color: t.processed_color] }
      else
        print(report.categories)
      end

      footer(report) { |value| type == :detailed ? value[0..2].unshift('') : value }
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
