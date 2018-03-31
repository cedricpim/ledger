module Ledger
  # Class holding the logic to print whatever query was made to the console.
  # Very simple and straightforward, the idea is to just be able to display
  # the title/header the and the respective summary.
  class Printer
    include ReportBuilder

    attr_reader :repository, :options

    def initialize(options = {})
      @repository = Ledger::Repository.new(options)
      @options = options
    end

    def balance
      title('Balance')

      table do
        main_header(of: :balance)

        repository.accounts.each_pair do |account, total|
          next if total.zero? && !options[:all]

          balance_row(account, total)
        end
      end

      totals(with_period: false)
    end

    def report
      repository.report.each do |report|
        title(report.account)

        build(report)
      end

      totals
    end

    def study(category)
      repository.study(category).each do |study|
        title(study.account)

        table do
          main_header(of: :study)

          print(study.descriptions)

          footer(study)
        end
      end
    end

    def trips
      list = repository.trips

      options[:global] ? trip_totals(list) : trip_individuals(list)

      totals
    end

    private

    def trip_individuals(list)
      list.each do |trip|
        title(trip.travel)

        build(trip)
      end
    end

    def trip_totals(list)
      title('Trips')

      table do
        main_header(of: :trip, type: :global)

        print(list.map(&:summary))

        add_row(trip_total_footer(list), CONFIG.color(:total))
      end
    end

    def trip_total_footer(list)
      total_spent = list.sum(&:total_spent)
      percentage = MoneyHelper.percentage(total_spent) do |value|
        [value, repository.relevant_transactions.select(&:income?).sum(&:money)]
      end

      ['Total'].push(MoneyHelper.display(total_spent), percentage)
    end

    def build(entity)
      table do
        main_header(of: entity.class.to_s.split('::').last.downcase.to_sym, type: :summary)

        print(entity.categories)

        footer(entity)
      end
    end

    def totals(with_period: true)
      title('Totals')

      table do
        total_period_row(with_period: with_period)
        total_current_row(with_period: with_period)
      end
    end
  end
end
