module Ledger
  # Class holding the logic to print whatever query was made to the console.
  # Very simple and straightforward, the idea is to just be able to display
  # the title/header the and the respective summary.
  class Printer
    include ReportBuilder

    attr_reader :repository, :options

    def initialize(options = {})
      @repository = Ledger::Repository.new
      @options = options
    end

    def list
      title('Transactions')

      table do
        main_header(of: :transaction, type: :list)

        print_detailed(repository.transactions, include_travel: true)
      end

      totals
    end

    def report
      repository.report(options).each do |report|
        title(report.account)

        build(report, :filtered_transactions) do |value|
          type == :detailed ? value[0..2].unshift('') : value
        end
      end

      totals
    end

    def trips
      repository.trips(options).each do |trip|
        title(trip.travel)

        build(trip, :transactions, include_account: true) do |value|
          type == :detailed ? value.unshift('', '') : value
        end
      end

      totals
    end

    private

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
        [t.details(options.merge(percentage_related_to: transactions)), color: t.processed_color]
      end
    end

    def footer(entity)
      total = yield(entity.total) if entity.respond_to?(:total)
      month = yield(entity.monthly) if entity.respond_to?(:monthly)

      add_row(total, color: :yellow)
      add_row(month, color: :magenta)
    end

    def totals
      title('Totals')

      table do
        row(color: :blue, bold: true) do
          repository.currencies.each_key { |k| column(k.name, width: 23, align: 'center') }
        end
        row(color: :white) do
          repository.currencies.each_value { |v| column(v, align: 'center') }
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
