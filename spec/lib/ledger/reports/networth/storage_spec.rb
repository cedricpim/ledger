RSpec.describe Ledger::Reports::Networth::Storage, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {currency: 'USD'} }

  # rubocop:disable Metrics/LineLength
  let(:ledger_content) do
    [
      build(:transaction, category: 'Investment', amount: '-2.00', currency: 'BBD', date: '2019-01-04', description: 'ISINA', quantity: '2'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-02', description: 'ISINA', quantity: '1'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-05', description: 'ISINB', quantity: '10'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-03', description: 'ISINC', quantity: '2'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-04', description: 'ISINC', quantity: '2'),
      build(:transaction, category: 'Something', amount: '+10.00', currency: 'USD', date: '2019-01-04', description: 'Else'),
      build(:transaction, account: 'Ignore', category: 'C', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'Ignore', amount: '-50.00', currency: 'USD')
    ]
  end
  # rubocop:enable Metrics/LineLength

  let(:quotes) do
    [
      instance_double('Ledger::API::JustETF', quote: Money.new(50 * 100, 'USD'), title: 'A'),
      instance_double('Ledger::API::JustETF', quote: Money.new(5 * 100, 'USD'), title: 'B'),
      instance_double('Ledger::API::JustETF', quote: Money.new(175 * 100, 'USD'), title: 'C')
    ]
  end

  before do
    allow(CONFIG).to receive(:exclusions).and_return(accounts: ['Ignore'], categories: ['Ignore'])

    quotes.each do |quote|
      allow(Ledger::API::JustETF).to receive(:new).with(isin: "ISIN#{quote.title}").and_return(quote)
    end
  end

  describe '#data' do
    subject { report.data(entry) }

    let(:entry) { nil }

    let(:date) { Date.new(2019, 1, 4) }

    let(:result) do
      {
        date: Date.new(2019, 1, 4),
        invested: Money.new(2 * 100, 'USD'),
        investment: Money.new(900 * 100, 'USD'),
        amount: Money.new(905 * 100, 'USD'),
        currency: 'USD'
      }
    end

    before { allow(Date).to receive(:today).and_return(date) }

    it { is_expected.to eq result }

    context 'when there are no investments for the current date' do
      let(:date) { Date.new(2019, 1, 30) }

      let(:result) do
        {
          date: Date.new(2019, 1, 30),
          invested: 0,
          investment: Money.new(900 * 100, 'USD'),
          amount: Money.new(905 * 100, 'USD'),
          currency: 'USD'
        }
      end

      it { is_expected.to eq result }
    end

    context 'when an entry is provided' do
      let(:entry) { build(:networth, date: '2019-01-05', investment: '+10.00', amount: '+15.00', currency: 'EUR') }

      let(:result) do
        {
          date: Date.new(2019, 1, 5),
          invested: Money.new(1 * 100, 'USD'),
          investment: Money.new(11.6 * 100, 'USD'),
          amount: Money.new(17.41 * 100, 'USD'),
          currency: 'USD'
        }
      end

      it { is_expected.to eq result }
    end
  end
end
