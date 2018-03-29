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

          add_balance_row(account, total)
        end
      end

      totals
    end

    def report
      repository.report.each do |report|
        title(report.account)

        build(report, :filtered_transactions) do |value|
          type == :detailed ? value[0..2].unshift('') : value
        end
      end

      totals
    end

    def study(category)
      repository.study(category).each do |study|
        title(study.account)

        table do
          main_header(of: :study)

          print(study.descriptions)

          footer(study) { |v| v }
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

        build(trip, :transactions, include_account: true) do |value|
          type == :detailed ? value.unshift('', '') : value
        end
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

    def build(entity, method, **options, &block)
      table do
        main_header(of: entity_name(entity), type: type)

        if type == :detailed
          print_detailed(entity.public_send(method), options)
        else
          print(entity.categories)
        end

        footer(entity, &block)
      end
    end

    def print_detailed(transactions, **options)
      print(transactions) do |t|
        [t.details(options.merge(percentage_related_to: transactions)), CONFIG.color(:processed, t.processed)]
      end
    end

    def totals
      title('Totals')

      table do
        row(CONFIG.color(:header)) do
          repository.currencies.each_key do |v|
            ts = repository.period_transactions.map { |t| t.exchange_to(v) }
            income = ts.reject(&:expense?).sum(&:money)
            expense = ts.select(&:expense?).sum(&:money)
            column(MoneyHelper.display(income)[1..-1], MoneyHelper.color(income).merge(width: 11, align: 'center'))
            column(MoneyHelper.display(expense)[1..-1], MoneyHelper.color(expense).merge(width: 11, align: 'center'))
          end
          column("55%", width: 10, align: 'center')
        end
        row(CONFIG.color(:header)) do
          repository.currencies.each_value do |v|
            column(v, width: 10, align: 'center', span: 2)
          end
          column("53%", width: 5, align: 'center')
        end
      end
    end

    def type
      options[:detailed] ? :detailed : :summary
    end

    def entity_name(entity)
      entity.class.to_s.split('::').last.downcase.to_sym
    end
  end
end
