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
    repository.report(options).each do |report|
      header(title: report.account, width: 60, align: 'center', rule: true)
      table do
        row(header: true, color: :blue) do
          column('Category', width: 20)
          column('Account', width: 20)
          column('All Accounts', width: 20)
        end
        [report.total, report.monthly_balance].each do |values|
          row do
            values.each { |v| column(v) }
          end
        end
        row(header: true, color: :blue) do
          column('Category', width: 20)
          column('Outflow', width: 20)
          column('Inflow', width: 20)
        end
        report.to_s(options).each do |values|
          row do
            values.each { |v| column(v) }
          end
        end
        row(bold: true, color: :yellow) do
          report.footer.each { |v| column(v) }
        end
      end
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
