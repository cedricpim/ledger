# Class holding the logic to print whatever query was made to the console.
# Very simple and straightforward, the idea is to just be able to display
# the title/header the and the respective summary.
class Printer
  attr_reader :ledger

  def initialize
    @ledger = Ledger.new
  end

  def balance
    accounts = ledger.accounts

    accounts.each { |account| account_details(account) }

    print('Totals') { account_totals(accounts) }
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
    result = yield
    puts result.respond_to?(:join) ? result.join("\n") : result
    puts
  end

  def account_details(account)
    print("#{account.name} [#{MoneyHelper.display(account.current)}]") do
      [account.balance].concat(account.categories)
    end
  end

  def account_totals(accounts)
    accounts.map(&:currency).uniq.map do |currency|
      MoneyHelper.display(ledger.transactions.sum { |t| t.money.exchange_to(currency) })
    end.join(' | ')
  end
end
