# Class holding the logic to print whatever query was made to the console.
# Very simple and straightforward, the idea is to just be able to display
# the title/header the and the respective summary.
class Printer
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
    repository.report(options).each do |report|
      print(report.title) { [report.monthly_balance].concat(report.to_s(options)).push(report.footer) }
    end
  end

  private

  def print(title)
    puts format(CONFIG.template(:title), title: title)
    result = yield
    puts result.respond_to?(:join) ? result.join("\n") : result
    puts
  end
end
