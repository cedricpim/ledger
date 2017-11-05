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
        main_header(:transaction)

        print(repository.transactions) do |t|
          [t.details(include_travel: true)[0..-2], color: t.processed_value ? :white : :black]
        end
      end

      totals
    end

    def trips
      repository.trips.each do |trip|
        print(trip.travel) { trip.to_s(options).push(trip.footer) }
      end
    end

    def report
      repository.report(options).each do |report|
        title(report.account)

        build_report(report, options[:detailed] ? :detailed : :summary)
      end

      totals
    end

    private

    def build_report(report, type)
      table do
        main_header(type)

        if type == :detailed
          print(report.filtered_transactions) { |t| [t.details, color: t.processed_value ? :white : :black] }
        else
          print(report.categories)
        end

        footer(report) { |value| type == :detailed ? value[0..2].unshift('') : value }
      end
    end
  end
end
