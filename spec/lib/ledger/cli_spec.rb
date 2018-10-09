RSpec.describe Ledger::Cli do
  subject(:cli) { described_class.new }

  let(:parsed_options_attrs) { {} }
  let(:parsed_options) { Thor::CoreExt::HashWithIndifferentAccess.new(parsed_options_attrs) }
  let(:options_attrs) { {} }
  let(:options) { Thor::CoreExt::HashWithIndifferentAccess.new(options_attrs) }

  RSpec.shared_context 'has currency option' do
    before do
      allow(cli).to receive(:options).and_return(options)
      allow_any_instance_of(Ledger::Config).to receive(:default_currency).and_return('USD')
    end
  end

  RSpec.shared_context 'has options' do
    include_context 'has currency option'

    let(:options_attrs) do
      super().merge(
        year: -> { Date.today.cwyear },
        month: -> { Date.today.month },
        from: '21/07/2018',
        till: '22/07/2018',
        global: true
      )
    end
    let(:parsed_options_attrs) do
      super().merge(
        year: 2018,
        month: 7,
        from: Date.new(2018, 7, 21),
        till: Date.new(2018, 7, 22),
        global: true
      )
    end

    before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 21)) }
  end

  RSpec.shared_examples 'printer receives' do |method, *params|
    let(:printer) { instance_double('Ledger::Printer') }

    specify do
      expect(Ledger::Printer).to receive(:new).with(parsed_options).and_return(printer)
      if params.empty?
        expect(printer).to receive(method)
        cli.public_send(method)
      else
        expect(printer).to receive(method).with(*params)
        cli.public_send(method, *params)
      end
    end
  end

  RSpec.shared_examples 'repository receives' do |method|
    let(:repository) { instance_double('Ledger::Repository') }
    let(:options_attrs) { super().merge(networth: true) }
    let(:parsed_options_attrs) { super().merge(networth: true) }

    before { allow(cli).to receive(:options).and_return(options) }

    specify do
      expect(Ledger::Repository).to receive(:new).with(parsed_options).and_return(repository)
      expect(repository).to receive(method)

      cli.public_send(method.to_s.chomp('!'))
    end

    context 'when CONFIG does not have networth' do
      let(:parsed_options_attrs) { super().tap { |h| h.delete(:networth) } }

      before { allow_any_instance_of(Ledger::Config).to receive(:networth?).and_return(false) }

      specify do
        expect(Ledger::Repository).to receive(:new).with(parsed_options).and_return(repository)
        expect(repository).to receive(method)

        cli.public_send(method.to_s.chomp('!'))
      end
    end
  end

  describe '#commands' do
    specify do
      expect(cli).to receive(:say).with(described_class::COMMANDS.keys.join("\n"))

      cli.commands
    end
  end

  describe '#compare' do
    let(:options_attrs) { {currency: -> { CONFIG.default_currency }} }
    let(:parsed_options_attrs) { {currency: 'USD'} }

    include_context 'has currency option'

    it_behaves_like 'printer receives', :compare
  end

  describe '#configure' do
    specify do
      expect(Ledger::Config).to receive(:configure)

      cli.configure
    end
  end

  describe '#create' do
    it_behaves_like 'repository receives', :create!
  end

  describe '#edit' do
    it_behaves_like 'repository receives', :edit!
  end

  describe '#book' do
    it_behaves_like 'repository receives', :book!
  end

  describe '#show' do
    it_behaves_like 'repository receives', :show
  end

  describe '#balance' do
    let(:options_attrs) { {date: '2018/10/28'} }
    let(:parsed_options_attrs) { {date: Date.new(2018, 10, 28)} }

    before { allow(cli).to receive(:options).and_return(options) }

    it_behaves_like 'printer receives', :balance
  end

  describe '#analysis' do
    include_context 'has options'

    it_behaves_like 'printer receives', :analysis, 'Category'
  end

  describe '#report' do
    include_context 'has options'

    it_behaves_like 'printer receives', :report
  end

  describe '#trip' do
    let(:options_attrs) { {currency: -> { CONFIG.default_currency }} }
    let(:parsed_options_attrs) { {currency: 'USD'} }

    include_context 'has currency option'

    it_behaves_like 'printer receives', :trip
  end

  describe '#networth' do
    it_behaves_like 'printer receives', :networth

    context 'when store is defined' do
      let(:options_attrs) { {store: true} }
      let(:parsed_options_attrs) { {store: true} }

      it_behaves_like 'repository receives', :networth!
    end
  end

  describe '#version' do
    specify do
      expect(cli).to receive(:say).with("ledger #{::Ledger::VERSION}")

      cli.version
    end
  end
end
