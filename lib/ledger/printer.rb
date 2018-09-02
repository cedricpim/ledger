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
          balance_row(account, total)
        end
      end

      totals(with_period: false)
    end

    def compare
      comparisons = repository.comparisons
      headers = build_comparison_header(comparisons.map(&:list))

      title('Comparison', width: headers.sum { |_elem, options| options[:width] } + headers.count)

      table { compare_rows(headers, comparisons) }
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

      widths.slice_after(&:zero?).map.with_index do |set, header_index|
        build_comparison_header_columns(set, header_index)
      end.flatten(1)
    end

    def build_comparison_header_columns(set, header_index)
      set.map.with_index do |width, period_index|
        next ['', width: 2] if width.zero?

        title = build_column_title(header_index, period_index)
        [title, width: [width, title.length].max + 1, align: 'center']
      end
    end

    def build_column_title(header_index, period_index)
      periods = repository.periods.flatten.map { |p| p.strftime('%m/%y') }.uniq
      title, starting = Ledger::Comparison::HEADERS[header_index]
      starting ? "#{title} (#{periods[period_index + starting]})" : title
    end

    def compare_rows(headers, comparisons)
      add_colored_row(headers, CONFIG.color(:header))

      comparisons.each do |comparison|
        add_colored_row(comparison.list, CONFIG.color(:element))
      end
    end
  end
end
