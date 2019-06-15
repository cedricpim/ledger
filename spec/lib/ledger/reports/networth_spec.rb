RSpec.describe Ledger::Reports::Networth, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {currency: 'USD'} }

  # rubocop:enable Metrics/LineLength
  let(:ledger_content) do
    [
      build(:transaction, category: 'Investment', amount: '-2.00', currency: 'BBD', date: '2019-01-04', description: 'ISINA - 2'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-02', description: 'ISINA'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-05', description: 'ISINB - 10'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-03', description: 'ISINC - 2'),
      build(:transaction, category: 'Investment', amount: '-1.00', currency: 'USD', date: '2019-01-04', description: 'ISINC - 2'),
      build(:transaction, category: 'Something', amount: '+10.00', currency: 'USD', date: '2019-01-04', description: 'Else'),
      build(:transaction, account: 'Ignore', category: 'C', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'Ignore', amount: '-50.00', currency: 'USD')
    ]
  end
  # rubocop:disable Metrics/LineLength

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
    subject { report.data }

    let(:result) do
      [
        {title: 'A', value: Money.new(150 * 100, 'USD'), percentage: 16.57},
        {title: 'C', value: Money.new(700 * 100, 'USD'), percentage: 77.35},
        {title: 'B', value: Money.new(50 * 100, 'USD'), percentage: 5.52},
        {title: 'Cash', value: Money.new(5 * 100, 'USD'), percentage: 0.55},
        {title: 'Total', value: Money.new(905 * 100, 'USD'), percentage: 100.0}
      ]
    end

    it { is_expected.to eq result }

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq [] }
    end

    context 'when JustETF raises an exception' do
      before { allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINA').and_raise(StandardError) }

      specify { expect { subject }.to raise_error(StandardError) }
    end

    context 'when currency is different' do
      let(:options) { {currency: 'BBD'} }
      let(:result) do
        [
          {title: 'A', value: Money.new(150 * 2 * 100, 'BBD'), percentage: 16.57},
          {title: 'C', value: Money.new(700 * 2 * 100, 'BBD'), percentage: 77.35},
          {title: 'B', value: Money.new(50 * 2 * 100, 'BBD'), percentage: 5.52},
          {title: 'Cash', value: Money.new(5 * 2 * 100, 'BBD'), percentage: 0.55},
          {title: 'Total', value: Money.new(905 * 2 * 100, 'BBD'), percentage: 100.0}
        ]
      end

      it { is_expected.to eq result }
    end
  end

  describe '#store' do
    subject { report.store }

    let(:date) { Date.new(2019, 1, 4) }

    let(:result) do
      {
        date: '2019-01-04',
        invested: Money.new(2 * 100, 'USD'),
        investment: Money.new(900 * 100, 'USD'),
        amount: Money.new(905 * 100, 'USD'),
        currency: 'USD'
      }
    end

    before { allow(Date).to receive(:today).and_return(date) }

    it { is_expected.to eq result }
  end
end
