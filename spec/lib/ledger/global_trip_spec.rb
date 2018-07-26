RSpec.describe Ledger::GlobalTrip do
  subject(:global_trip) { described_class.new(travel, transactions, total_transactions) }

  let(:travel) { 'Some Travel' }
  let(:transactions) do
    [
      t(travel: travel, date: '20/07/2018', amount: -20, currency: 'USD'),
      t(travel: travel, date: '21/07/2018', amount: -75, currency: 'USD'),
      t(travel: "#{travel} 2", date: '19/07/2018', amount: -5, currency: 'USD'),
      t(travel: "#{travel} 2", date: '19/07/2018', amount: -5, currency: 'USD')
    ]
  end
  let(:total_transactions) do
    [
      t(date: '18/07/2018', amount: -20, currency: 'USD'),
      t(date: '22/07/2018', amount: 150, currency: 'USD')
    ] + transactions
  end

  describe '#list' do
    subject { global_trip.list }

    let(:result) { [["#{travel} 2", '-10.00$', 9.52], [travel, '-95.00$', 90.48]] }

    it { is_expected.to eq result }
  end

  describe '#total' do
    subject { global_trip.total }

    it { is_expected.to eq ['Total', '-105.00$', 84.0] }
  end
end
