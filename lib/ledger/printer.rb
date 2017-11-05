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
          [t.details(include_travel: true)[0..-2], color: t.processed_value ? :white : :black]
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

          [values, color: t.processed_value ? :white : :black]
        end
      else
        print(trip.categories)
      end

      add_row(trip.total(type), color: :yellow)
    end

    def build_report(report, type)
      if type == :detailed
        print(report.filtered_transactions) do |t|
          [t.details, color: t.processed_value ? :white : :black]
        end
      else
        print(report.categories)
      end

      footer(report) { |value| type == :detailed ? value[0..2].unshift('') : value }
    end
  end
end
