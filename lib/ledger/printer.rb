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

    def trip
      repository.trips.each do |trip|
        title(trip.travel)

        build(trip)
      end
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
  end
end
