RSpec.describe Ledger::Cli do
  subject(:cli) { described_class.new }

  RSpec.shared_context 'has options' do
    let(:options_attrs) do
      {
        currency: -> { CONFIG.default_currency },
        year: -> { Date.today.year },
        month: -> { Date.today.month },
        from: '2018/07/21',
        till: '2018/07/22',
        date: '2018/07/23'
      }
    end
    let(:parsed_options_attrs) do
      {
        currency: 'USD',
        year: 2018,
        month: 7,
        from: Date.new(2018, 7, 21),
        till: Date.new(2018, 7, 22),
        date: Date.new(2018, 7, 23)
      }
    end
    let(:options) { Thor::CoreExt::HashWithIndifferentAccess.new(options_attrs) }
    let(:parsed_options) { Thor::CoreExt::HashWithIndifferentAccess.new(parsed_options_attrs) }

    before do
      allow(CONFIG).to receive(:default_currency).and_return('USD')
      allow(Date).to receive(:today).and_return(Date.new(2018, 7, 20))
      allow(cli).to receive(:options).and_return(options)
    end
  end

  RSpec.shared_examples 'calls action' do |klass, method|
    let(:action) { instance_double(klass.to_s) }

    specify do
      expect(klass).to receive(:new).with(parsed_options).and_return(action)
      expect(action).to receive(:call)

      cli.public_send(method)
    end
  end

  include_context 'has options'

  describe '#commands' do
    specify do
      expect(cli).to receive(:say).with(described_class::COMMANDS.keys.join("\n"))

      cli.commands
    end
  end

  describe '#configure' do
    it_behaves_like 'calls action', Ledger::Actions::Configure, :configure
  end

  describe '#convert' do
    it_behaves_like 'calls action', Ledger::Actions::Convert, :convert
  end

  describe '#create' do
    it_behaves_like 'calls action', Ledger::Actions::Create, :create
  end

  describe '#edit' do
    it_behaves_like 'calls action', Ledger::Actions::Edit, :edit

    context 'when networth is not enabled' do
      let(:options_attrs) { {networth: true} }
      let(:action) { instance_double(Ledger::Actions::Edit.to_s) }

      before { allow(CONFIG).to receive(:networth?).and_return(false) }

      specify do
        expect(Ledger::Actions::Edit).to receive(:new).with({}).and_return(action)
        expect(action).to receive(:call)

        cli.edit
      end
    end
  end

  describe '#book' do
    it_behaves_like 'calls action', Ledger::Actions::Book, :book
  end

  describe '#show' do
    it_behaves_like 'calls action', Ledger::Actions::Show, :show

    context 'when networth is not enabled' do
      let(:options_attrs) { {networth: true} }
      let(:action) { instance_double(Ledger::Actions::Show.to_s) }

      before { allow(CONFIG).to receive(:networth?).and_return(false) }

      specify do
        expect(Ledger::Actions::Show).to receive(:new).with({}).and_return(action)
        expect(action).to receive(:call)

        cli.show
      end
    end
  end

  describe '#analysis' do
    let(:report) { instance_double('Ledger::Reports::Analysis', ledger: 'ledger', data: 'data', global: 'global') }
    let(:printer) { instance_double('Ledger::Printers::Analysis') }
    let(:category) { 'X' }

    specify do
      expect(Ledger::Reports::Analysis).to receive(:new).with(parsed_options, category: category).and_return(report)
      expect(Ledger::Printers::Analysis).to receive(:new).with(parsed_options, total: Proc).and_return(printer)
      expect(printer).to receive(:call).with('data')

      cli.analysis(category)
    end

    context 'when it is global' do
      let(:options_attrs) { super().merge(global: true) }
      let(:parsed_options_attrs) { super().merge(global: true) }

      specify do
        expect(Ledger::Reports::Analysis).to receive(:new).with(parsed_options, category: category).and_return(report)
        expect(Ledger::Printers::Analysis).to receive(:new).with(parsed_options, total: Proc).and_return(printer)
        expect(printer).to receive(:call).with('global')

        cli.analysis(category)
      end
    end
  end

  describe '#balance' do
    let(:report) { instance_double('Ledger::Reports::Balance', ledger: 'ledger', data: 'data') }
    let(:printer) { instance_double('Ledger::Printers::Balance') }

    specify do
      expect(Ledger::Reports::Balance).to receive(:new).with(parsed_options).and_return(report)
      expect(Ledger::Printers::Balance).to receive(:new).with(parsed_options, total: Proc).and_return(printer)
      expect(printer).to receive(:call).with('data')

      cli.balance
    end
  end

  describe '#compare' do
    let(:report) { instance_double('Ledger::Reports::Comparison', periods: 'periods', data: 'data', totals: 'totals') }
    let(:printer) { instance_double('Ledger::Printers::Comparison') }

    specify do
      expect(Ledger::Reports::Comparison).to receive(:new).with(parsed_options).and_return(report)
      expect(Ledger::Printers::Comparison).to receive(:new).with(parsed_options).and_return(printer)
      expect(printer).to receive(:call).with('periods', 'data', 'totals')

      cli.compare
    end
  end

  describe '#report' do
    let(:report) { instance_double('Ledger::Reports::Report', ledger: 'ledger', data: 'data', global: 'global') }
    let(:printer) { instance_double('Ledger::Printers::Report') }

    specify do
      expect(Ledger::Reports::Report).to receive(:new).with(parsed_options).and_return(report)
      expect(Ledger::Printers::Report).to receive(:new).with(parsed_options, total: Proc).and_return(printer)
      expect(printer).to receive(:call).with('data')

      cli.report
    end

    context 'when it is global' do
      let(:options_attrs) { super().merge(global: true) }
      let(:parsed_options_attrs) { super().merge(global: true) }

      specify do
        expect(Ledger::Reports::Report).to receive(:new).with(parsed_options).and_return(report)
        expect(Ledger::Printers::Report).to receive(:new).with(parsed_options, total: Proc).and_return(printer)
        expect(printer).to receive(:call).with('global')

        cli.report
      end
    end
  end

  describe '#trip' do
    let(:report) { instance_double('Ledger::Reports::Trip', ledger: 'ledger', data: 'data', global: 'global') }
    let(:printer) { instance_double('Ledger::Printers::Trip') }

    specify do
      expect(Ledger::Reports::Trip).to receive(:new).with(parsed_options).and_return(report)
      expect(Ledger::Printers::Trip).to receive(:new).with(parsed_options).and_return(printer)
      expect(printer).to receive(:call).with('data')

      cli.trip
    end

    context 'when it is global' do
      let(:options_attrs) { super().merge(global: true) }
      let(:parsed_options_attrs) { super().merge(global: true) }

      specify do
        expect(Ledger::Reports::Trip).to receive(:new).with(parsed_options).and_return(report)
        expect(Ledger::Printers::Trip).to receive(:new).with(parsed_options).and_return(printer)
        expect(printer).to receive(:call).with('global')

        cli.trip
      end

      context 'when a trip is also defined' do
        let(:options_attrs) { super().merge(trip: 'T') }
        let(:parsed_options_attrs) { super().merge(trip: 'T') }

        specify do
          expect(Ledger::Reports::Trip).to receive(:new).with(parsed_options.except('global')).and_return(report)
          expect(Ledger::Printers::Trip).to receive(:new).with(parsed_options.except('global')).and_return(printer)
          expect(printer).to receive(:call).with('data')

          cli.trip
        end
      end
    end
  end

  describe '#networth' do
    let(:report) { instance_double('Ledger::Reports::Networth', ledger: 'ledger', data: 'data', store: 'store') }
    let(:printer) { instance_double('Ledger::Printers::Networth') }

    specify do
      expect(Ledger::Reports::Networth).to receive(:new).with(parsed_options).and_return(report)
      expect(Ledger::Printers::Networth).to receive(:new).with(parsed_options).and_return(printer)
      expect(printer).to receive(:call).with('data')

      cli.networth
    end

    context 'when it is set to store' do
      let(:options_attrs) { super().merge(store: true) }
      let(:parsed_options_attrs) { super().merge(store: true) }
      let(:action) { instance_double('Ledger::Actions::Networth') }

      specify do
        expect(Ledger::Reports::Networth).to receive(:new).with(parsed_options).and_return(report)
        expect(Ledger::Actions::Networth).to receive(:new).with(parsed_options, ledger: 'ledger').and_return(action)
        expect(action).to receive(:call).with('store')

        cli.networth
      end
    end
  end

  describe '#version' do
    specify do
      expect(cli).to receive(:say).with("ledger #{::Ledger::VERSION}")

      cli.version
    end
  end
end
