RSpec.describe Ledger::Config do
  subject(:config) { described_class.new(file: described_class::FALLBACK_CONFIG) }

  describe '#default?' do
    subject { config.default? }

    before { stub_const("#{described_class}::DEFAULT_CONFIG", File.join(File.expand_path('../../', __dir__))) }

    it { is_expected.to eq true }

    context 'when default file does not exist' do
      before { stub_const("#{described_class}::DEFAULT_CONFIG", rand.to_s) }

      it { is_expected.to eq false }
    end
  end

  describe '#ledger' do
    subject { config.ledger }

    it { is_expected.to eq 'spec/fixtures/example.csv' }
  end

  describe '#networth' do
    subject { config.networth }

    it { is_expected.to eq 'spec/fixtures/example-networth.csv' }
  end

  describe '#investments' do
    subject { config.investments }

    it { is_expected.to eq ['Investment'] }

    context 'when there are no investments defined' do
      before { expect(config).to receive(:config).and_return(networth: {file: 'some file'}) }

      it { is_expected.to eq [] }
    end
  end

  describe '#exchange' do
    subject { config.exchange }

    it { is_expected.to eq(cache_file: 'spec/fixtures/exchange-cache.json') }
  end

  describe '#fields' do
    subject { config.fields }

    let(:result) do
      {
        account: {default: 'Account', presence: true},
        amount: {presence: true},
        category: {presence: true},
        currency: {default: 'USD', presence: true},
        date: {default: '2018-07-22', presence: true},
        description: {presence: false},
        trip: {presence: false},
        venue: {presence: false}
      }
    end

    before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 22)) }

    it { is_expected.to eq result }
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

    it { is_expected.to eq 'USD' }

    context 'when there are no default for currency' do
      before { expect(config).to receive(:config).and_return(fields: {currency: {values: %w[EUR]}}) }

      it { is_expected.to eq 'EUR' }
    end
  end

  describe '#default_value' do
    subject { config.default_value }

    it { is_expected.to eq '------' }
  end

  describe '#exclusions' do
    subject { config.exclusions(type: :report) }

    let(:structure) { {accounts: ['Ignore'], categories: ['Ignore2']} }

    before { expect(config).to receive(:config).and_return(report: {exclude: structure}) }

    it { is_expected.to eq(accounts: %w[Ignore], categories: %w[Ignore2]) }

    context 'when there are no exclusions' do
      let(:structure) { {} }

      it { is_expected.to eq(accounts: [], categories: []) }
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
    let(:result) { {sign_positive: true, decimal_mark: '.', thousands_separator: ',', format: '%n%u'} }

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
