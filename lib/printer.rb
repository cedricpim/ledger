# Class holding the logic to print whatever query was made to the console.
# Very simple and straightforward, the idea is to just be able to display
# the title/header the and the respective summary.
class Printer
  attr_reader :ledger

  def initialize
    @ledger = Ledger.new
  end

  def balance
    print('Balance') { ledger.accounts }
  end

  def categories
    print('Categories') { ledger.categories }
  end

  def list
    print('Transactions') { ledger.list }
  end

  def trips(options)
    ledger.trips.each do |trip|
      print(trip.travel) { trip.to_s(options).push(trip.footer) }
    end
  end

  def report(options)
    ledger.report(options).each do |report|
      print(report.account) { report.to_s(options).push(report.footer) }
    end
  end

  private

  def print(title)
    puts format(CONFIGS.dig(:format, :title), title: title)
    puts yield.join("\n")
    puts
  end
end
