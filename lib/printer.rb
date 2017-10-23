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

  def transactions
    print('Transactions') { ledger.transactions }
  end

  def trips(options)
    ledger.trips.each do |trip|
      print(trip.travel) { trip.to_s(options).push(trip.totals) }
    end
  end

  def report(options)
    ledger.report(options).each do |report|
      print(report.account) { report.to_s(options).push(report.total_text) }
    end
  end

  private

  def print(title)
    puts "####### #{title} #######"
    puts yield.join("\n")
    puts ''
  end
end
