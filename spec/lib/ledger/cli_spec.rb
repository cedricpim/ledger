RSpec.describe Ledger::Cli do
  subject(:cli) { described_class.new }

  let(:parsed_options_attrs) { {} }
  let(:parsed_options) { Thor::CoreExt::HashWithIndifferentAccess.new(parsed_options_attrs) }
  let(:options_attrs) { {} }
  let(:options) { Thor::CoreExt::HashWithIndifferentAccess.new(options_attrs) }

  RSpec.shared_context 'has currency option' do
    let(:options_attrs) { {currency: -> { CONFIG.default_currency }} }
    let(:parsed_options_attrs) { {currency: 'USD'} }

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

    specify do
      expect(Ledger::Repository).to receive(:new).and_return(repository)
      expect(repository).to receive(method)

      cli.public_send(method.to_s.chomp('!'))
    end
  end

  describe '#commands' do
    specify do
      expect(cli).to receive(:say).with(described_class::COMMANDS.keys.join("\n"))

      cli.commands
    end
  end

  describe '#compare' do
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

  describe '#add' do
    it_behaves_like 'repository receives', :add!
  end

  describe '#balance' do
    it_behaves_like 'printer receives', :balance
  end

  describe '#study' do
    include_context 'has options'

    it_behaves_like 'printer receives', :study, 'Category'
  end

  describe '#report' do
    include_context 'has options'

    it_behaves_like 'printer receives', :report
  end

  describe '#trips' do
    include_context 'has currency option'

    it_behaves_like 'printer receives', :trips
  end

  describe '#version' do
    specify do
      expect(cli).to receive(:say).with("ledger #{::Ledger::VERSION}")

      cli.version
    end
  end
end
