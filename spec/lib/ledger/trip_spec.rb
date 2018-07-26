RSpec.describe Ledger::Trip do
  subject(:trip) { described_class.new(travel, transactions, total_transactions) }

  let(:travel) { 'Some Travel' }
  let(:transactions) do
    [
      t(travel: travel, category: 'A', date: '20/07/2018', amount: -20, currency: 'USD'),
      t(travel: travel, category: 'B', date: '21/07/2018', amount: -75, currency: 'USD'),
      t(travel: travel, category: 'A', date: '19/07/2018', amount: -5, currency: 'USD'),
      t(travel: travel, category: 'C', date: '19/07/2018', amount: -5, currency: 'USD')
    ]
  end
  let(:total_transactions) do
    [
      t(date: '18/07/2018', amount: -20, currency: 'USD'),
      t(date: '22/07/2018', amount: 150, currency: 'USD')
    ] + transactions
  end

  describe '#date' do
    subject { trip.date }

    it { is_expected.to eq Date.new(2018, 7, 21) }
  end

  describe '#list' do
    subject { trip.list }

    let(:result) { [['B', '-75.00$', 71.43], ['A', '-25.00$', 23.81], ['C', '-5.00$', 4.76]] }

    it { is_expected.to eq result }
  end

  describe '#total' do
    subject { trip.total }

    it { is_expected.to eq ['Total', '-105.00$', 70.0] }
  end
end
