RSpec.describe Ledger::Config do
  subject(:config) { described_class.new(described_class::FALLBACK_CONFIG) }

  describe '.configure' do
    subject { described_class.configure }

    context 'default configuration exists' do
      before { allow(File).to receive(:exist?).with(described_class::DEFAULT_CONFIG).and_return(true) }

      it { is_expected.to be_nil }
    end

    context 'default configuration does not exist' do
      before { allow(File).to receive(:exist?).with(described_class::DEFAULT_CONFIG).and_return(false) }

      specify do
        expect(File).to receive(:dirname).with(described_class::DEFAULT_CONFIG).and_return('dirname')
        expect(FileUtils).to receive(:mkdir_p).with('dirname')
        expect(FileUtils).to receive(:cp).with(described_class::FALLBACK_CONFIG, described_class::DEFAULT_CONFIG)

        subject
      end
    end
  end

  describe '.file' do
    subject { described_class.file }

    context 'default configuration exists' do
      before { allow(File).to receive(:exist?).with(described_class::DEFAULT_CONFIG).and_return(true) }

      it { is_expected.to eq described_class::DEFAULT_CONFIG }
    end

    context 'fallback configuration exists' do
      before do
        allow(File).to receive(:exist?).with(described_class::DEFAULT_CONFIG).and_return(false)
        allow(File).to receive(:exist?).with(described_class::FALLBACK_CONFIG).and_return(true)
      end

      it { is_expected.to eq described_class::FALLBACK_CONFIG }
    end

    context 'no configuration exists' do
      before do
        allow(File).to receive(:exist?).with(described_class::DEFAULT_CONFIG).and_return(false)
        allow(File).to receive(:exist?).with(described_class::FALLBACK_CONFIG).and_return(false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#ledger' do
    subject { config.ledger }

    it { is_expected.to eq "#{XDG['CONFIG']}/ledger/ledger.csv" }
  end

  describe '#exchange' do
    subject { config.exchange }

    it { is_expected.to eq(cache_file: 'spec/fixtures/exchange-cache.json') }
  end

  describe '#fields' do
    subject { config.fields }

    let(:categories) do
      [
        'Business', 'Electronics', 'Insurances', 'Taxes', 'Entertainment', 'Rentals',
        'Restaurants', 'Coffee', 'Public Transport', 'Groceries', 'Taxi', 'Fees & Charges',
        'Beers', 'Education', 'Travel', 'Personal Care', 'Mobile Phone'
      ]
    end

    let(:result) do
      {
        account: {default: 'Main', presence: true},
        amount: {default: '', presence: true},
        category: {default: '', presence: true, values: categories},
        currency: {default: 'EUR', presence: true, values: %w[EUR USD]},
        date: {default: '2018-07-22', presence: true},
        description: {default: '', presence: false},
        processed: {default: 'yes', presence: true, values: %w[yes no]},
        travel: {default: '', presence: false},
        venue: {default: '', presence: false}
      }
    end

    before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 22)) }

    it { is_expected.to eq result }
  end

  describe '#transaction_fields' do
    subject { config.transaction_fields }

    let(:keys) { %i[account date category description venue amount currency processed travel] }

    it { is_expected.to eq keys }
  end

  describe '#encryption' do
    subject { config.encryption }

    let(:result) do
      {
        enabled: false,
        algorithm: 'AES-256-CBC',
        credentials: {
          salt: 'some_salt',
          password: 'some_password',
          salteval: 'gpg -q --for-your-eyes-only --no-tty -d salt.gpg',
          passwordeval: 'gpg -q --for-your-eyes-only --no-tty -d password.gpg'
        }
      }
    end

    it { is_expected.to eq result }
  end

  describe '#credentials' do
    subject { config.credentials }

    it { is_expected.to eq %w[some_password some_salt] }

    context 'when there are no direct credentials defined' do
      let(:encryption) do
        {
          credentials: {
            salteval: 'echo "salt"',
            passwordeval: 'echo "password"'
          }
        }
      end

      before { allow(config).to receive(:encryption).and_return(encryption) }

      it { is_expected.to eq %w[password salt] }
    end
  end

  describe '#default_currency' do
    subject { config.default_currency }

    it { is_expected.to eq 'EUR' }

    context 'when there are no default for currency' do
      before { expect(config).to receive(:config).and_return(fields: {currency: {values: %w[USD]}}) }

      it { is_expected.to eq 'USD' }
    end
  end

  describe '#default_value' do
    subject { config.default_value }

    it { is_expected.to eq '------' }
  end

  describe '#excluded_categories' do
    subject { config.excluded_categories }

    it { is_expected.to eq %w[Exchange] }

    context 'when there are no categories' do
      before { expect(config).to receive(:config).and_return(report: {exclude: {}}) }

      it { is_expected.to eq [] }
    end
  end

  describe '#color' do
    subject { config.color(:header) }

    it { is_expected.to eq(color: :blue, bold: true) }
  end

  describe '#output' do
    subject { config.output(:color, :period) }

    it { is_expected.to eq(color: :magenta) }
  end

  describe '#money_format' do
    let(:result) do
      {sign_positive: true, decimal_mark: '.', symbol_after_without_space: true, symbol_position: :after}
    end

    context 'for display' do
      subject { config.money_format(type: :display) }

      it { is_expected.to eq result }
    end

    context 'for ledger' do
      subject { config.money_format(type: :ledger) }

      let(:result) { super().merge(symbol: false, thousands_separator: '') }

      it { is_expected.to eq result }
    end
  end

  describe '#show_totals?' do
    subject { config.show_totals? }

    it { is_expected.to eq true }

    context 'when show_totals is set to false' do
      before { expect(config).to receive(:config).and_return(format: {output: {show_totals: false}}) }

      it { is_expected.to eq false }
    end

    context 'when show_totals is not set' do
      before { expect(config).to receive(:config).and_return(format: {output: {}}) }

      it { is_expected.to be_nil }
    end
  end
end