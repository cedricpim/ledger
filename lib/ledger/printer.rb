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
    print('Transactions') { repository.list }
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
