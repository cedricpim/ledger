RSpec.describe Ledger::Reports::Comparison, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {months: 1} }

  before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 22)) }

  let(:ledger_content) do
    [
      build(:transaction, account: 'B', category: 'B', date: '15/07/2018', amount: '+75.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'A', date: '20/06/2018', amount: '-20.00', currency: 'BBD'),
      build(:transaction, account: 'A', category: 'A', date: '14/07/2018', amount: '-20.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'B', date: '16/06/2018', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'Ignore', category: 'X', date: '18/07/2018', amount: '+25.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'Ignore', date: '14/06/2018', amount: '-50.00', currency: 'USD')
    ]
  end

  before { allow(CONFIG).to receive(:exclusions).and_return(accounts: ['Ignore'], categories: ['Ignore']) }

  describe '#periods' do
    subject { report.periods }

    context 'when number of months go to previous year' do
      let(:options) { {months: 8} }

      let(:periods) do
        [
          [Date.new(2017, 11, 1), Date.new(2017, 11, 30)],
          [Date.new(2017, 12, 1), Date.new(2017, 12, 31)],
          [Date.new(2018, 1, 1), Date.new(2018, 1, 31)],
          [Date.new(2018, 2, 1), Date.new(2018, 2, 28)],
          [Date.new(2018, 3, 1), Date.new(2018, 3, 31)],
          [Date.new(2018, 4, 1), Date.new(2018, 4, 30)],
          [Date.new(2018, 5, 1), Date.new(2018, 5, 31)],
          [Date.new(2018, 6, 1), Date.new(2018, 6, 30)],
          [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]
        ]
      end

      it { is_expected.to eq periods }
    end

    context 'when number of months do not go to previous year' do
      let(:options) { {months: 3} }

      let(:periods) do
        [
          [Date.new(2018, 4, 1), Date.new(2018, 4, 30)],
          [Date.new(2018, 5, 1), Date.new(2018, 5, 31)],
          [Date.new(2018, 6, 1), Date.new(2018, 6, 30)],
          [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]
        ]
      end

      it { is_expected.to eq periods }
    end
  end

  describe '#data' do
    subject { report.data }

    let(:result) do
      [
        {
          title: 'A',
          absolutes: [Money.new(-20 * 100, 'BBD'), Money.new(-20 * 100, 'USD')],
          diffs: [Money.new(-10 * 100, 'USD')],
          percentages: [-100.00]
        },
        {
          title: 'B',
          absolutes: [Money.new(-50 * 100, 'USD'), Money.new(75 * 100, 'USD')],
          diffs: [Money.new(125 * 100, 'USD')],
          percentages: [250.0]
        },
        {
          title: 'X',
          absolutes: [Money.new(0, 'USD'), Money.new(25 * 100, 'USD')],
          diffs: [Money.new(25 * 100, 'USD')],
          percentages: [nil]
        }
      ]
    end

    it { is_expected.to eq result }

    context 'with currency' do
      let(:options) { super().merge(currency: 'USD') }

      before { result[0][:absolutes] = [Money.new(-10 * 100, 'USD'), Money.new(-20 * 100, 'USD')] }

      it { is_expected.to eq result }
    end

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq [] }
    end
  end

  describe '#totals', :streaming do
    subject { report.totals }

    let(:result) do
      {
        title: 'Totals',
        absolutes: [Money.new(-120 * 100, 'BBD'), Money.new(80 * 100, 'USD')],
        diffs: [Money.new(140 * 100, 'USD')],
        percentages: [233.33]
      }
    end

    it { is_expected.to eq result }

    context 'with currency' do
      let(:options) { super().merge(currency: 'USD') }

      before { result[:absolutes] = [Money.new(-60 * 100, 'USD'), Money.new(80 * 100, 'USD')] }

      it { is_expected.to eq result }
    end

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      let(:zero) { Money.new(0, 'USD') }

      let(:result) do
        {
          title: 'Totals',
          absolutes: [zero, zero],
          diffs: [zero],
          percentages: [nil]
        }
      end

      it { is_expected.to eq result }
    end
  end
end
