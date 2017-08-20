# Class holding the logic to print whatever query was made to the console.
# Very simple and straightforward, the idea is to just be able to display
# the title/header the and the respective summary.
class Printer
  attr_reader :ledger

  def initialize(ledger)
    @ledger = ledger
  end

  def balance
    print('Balance') { ledger.accounts.values.join("\n") }
  end

  def categories
    print('Categories') { ledger.existing_categories.join("\n") }
  end

  def transactions
    print('Transactions') { ledger.transactions.join("\n") }
  end

  def travels(options)
    trips = ledger.travels

    trips.each { |trip| print(trip.travel) { trip.to_s(options).join("\n") } }

    print('Totals') { trips.map(&:totals).join("\n") }
  end

  def report(options)

  end

  private

  def print(title)
    puts "####### #{title} #######"
    puts yield
    puts ''
  end
end
