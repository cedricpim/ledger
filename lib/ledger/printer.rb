module Ledger
  # Class holding the logic to print whatever query was made to the console.
  # Very simple and straightforward, the idea is to just be able to display
  # the title/header the and the respective summary.
  class Printer
    include CommandLineReporter

    attr_reader :repository, :options

    def initialize(options = {})
      @repository = Ledger::Repository.new(options)
      @options = options
    end

    def networth
      title('Networth Balance')

      build(NetworthCalculation.new(repository.load(:ledger), options[:currency]).networth, width: :auto)
    end

    private

    def build(entity, **options)
      table(options) do
        main_header(from: entity.class.to_s.split('::').last.downcase.to_sym)

        print(entity.list)

        add_row(entity.total, CONFIG.color(:total)) if entity.respond_to?(:total)
      end
    end

    def title(title, options = {})
      header(CONFIG.output(:title).merge(title: title).merge(options))
    end

    def main_header(from:)
      add_row(CONFIG.output(from, :header), CONFIG.output(from, :options), CONFIG.color(:header))
    end

    def print(list)
      list.each { |elements| add_row(elements, CONFIG.color(:element)) }
    end

    def add_colored_row(list, row_options = {})
      return unless list

      row(row_options) do
        list.each { |elem| column(*elem) }
      end
    end

    def add_row(list, column_options = [], **row_options)
      return unless list

      row(row_options) do
        list.each_with_index { |v, i| column(v, column_options.fetch(i, {})) }
      end
    end
  end
end
