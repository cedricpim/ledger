module Ledger
  # Class holding the logic to print whatever query was made to the console.
  # Very simple and straightforward, the idea is to just be able to display
  # the title/header the and the respective summary.
  class Printer
    include CommandLineReporter

    attr_reader :repository, :options

    def initialize(options = {})
      @repository = Ledger::Repository.new
      @options = options
    end

    def list
      header(Report::TITLE.merge(title: 'Transactions'))
      table do
        row(color: :blue, bold: true) do
          Report::HEADER[:detailed][0..-2].push('Trip').each_with_index do |v, i|
            column(v, Report::HEADER_OPTIONS[:detailed].fetch(i, {}))
          end
        end
        repository.transactions.each do |transaction|
          values = transaction.details
          row(color: values.pop ? :white : :black) do
            values[0..-2].push(transaction.travel || '-' * 6).each { |v| column(v) }
          end
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
      repository.report(options).each { |report| report.display(options[:detailed]) }

      totals
    end

    private

    def totals
      header(Report::TITLE.merge(title: 'Totals'))
      table do
        row(color: :blue, bold: true) do
          repository.currencies.each_key { |k| column(k.name, width: 23, align: 'center') }
        end
        row(color: :white) do
          repository.currencies.each_value { |v| column(v, align: 'center') }
        end
      end
    end

    def print(title)
      puts format(CONFIG.template(:title), title: title)
      result = yield
      puts result.respond_to?(:join) ? result.join("\n") : result
      puts
    end
  end
end
