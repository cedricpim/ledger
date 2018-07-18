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
        main_header(from: :balance)

        repository.accounts.each_pair do |account, total|
          next if total.zero? && !options[:all]

          balance_row(account, total)
        end
      end

      totals(with_period: false)
    end

    def compare
      title('Comparison')

      table do
        comparisons = repository.comparisons

        build_comparison_header(comparisons.map(&:list))

        comparisons.each do |comparison|
          add_row(comparison.list.map(&:first), comparison.list.map(&:last), color: :white, bold: true)
        end
      end
    end

    def report
      repository.reports.each do |report|
        title(report.account)

        build(report)
      end

      totals
    end

    def study(category)
      repository.studies(category).each do |study|
        title(study.account)

        build(study)
      end

      totals
    end

    def trips
      repository.trips.each do |trip|
        title(trip.travel)

        build(trip)
      end
    end

    private

    def build(entity)
      table do
        main_header(from: entity.class.to_s.split('::').last.downcase.to_sym)

        print(entity.list)

        add_row(entity.total, CONFIG.color(:total)) if entity.respond_to?(:total)
      end
    end

    def totals(with_period: true)
      title('Totals')

      table do
        total_period_row(with_period: with_period)
        total_current_row(with_period: with_period) if CONFIG.show_totals?
      end
    end

    def build_comparison_header(lists)
      widths = Array.new(lists.first.count) { |i| lists.map { |list| list[i][0].length }.max }

      row(CONFIG.color(:header)) do
        widths.slice_after(&:zero?).each.with_index do |set, header_index|
          build_comparison_header_columns(set, header_index)
        end
      end
    end

    def build_comparison_header_columns(set, header_index)
      set.each.with_index do |width, period_index|
        if width.zero?
          column('', width: 2)
        else
          title = build_column_title(header_index, period_index)
          column(title, width: [width, title.length].max + 1, align: 'center')
        end
      end
    end

    def build_column_title(header_index, period_index)
      periods = repository.periods.flatten.map { |p| p.strftime('%m/%y') }.uniq
      title, starting = Ledger::Comparison::HEADERS[header_index]
      starting ? "#{title} (#{periods[period_index + starting]})" : title
    end
  end
end
