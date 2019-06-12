RSpec.describe Ledger::Reports::Balance, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {} }

  let(:ledger_content) do
    [
      build(:transaction, account: 'B', date: '15/07/2018', amount: '-75.00', currency: 'USD'),
      build(:transaction, account: 'A', date: '14/07/2018', amount: '+20.00', currency: 'USD'),
      build(:transaction, account: 'A', date: '20/06/2018', amount: '+20.00', currency: 'BBD'),
      build(:transaction, account: 'B', date: '16/06/2018', amount: '+50.00', currency: 'USD'),
      build(:transaction, account: 'X', date: '18/05/2018', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'X', date: '19/05/2018', amount: '+50.00', currency: 'USD')
    ]
  end

  describe '#data' do
    subject { report.data }

    let(:result) do
      [
        {title: 'A', value: Money.new(60 * 100, 'BBD')},
        {title: 'B', value: Money.new(-25 * 100, 'USD')},
        {title: 'X', value: nil}
      ]
    end

    it { is_expected.to eq result }

    context "when the option 'all' is passed" do
      let(:options) { {all: true} }

      before { result.last[:value] = Money.new(0, 'USD') }

      it { is_expected.to eq result }
    end

    context 'when a date is provided' do
      let(:options) { {date: Date.new(2018, 6, 16)} }

      let(:result) do
        [
          {title: 'B', value: Money.new(50 * 100, 'USD')},
          {title: 'X', value: nil}
        ]
      end

      it { is_expected.to eq result }
    end
  end
end
