RSpec.describe Ledger::Reports::Total, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {} }

  let(:ledger_content) do
    [
      build(:transaction, account: 'B', category: 'B', date: '2018/07/15', amount: '+75.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'A', date: '2018/06/20', amount: '-20.00', currency: 'BBD'),
      build(:transaction, account: 'A', category: 'A', date: '2018/07/14', amount: '-20.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'B', date: '2018/06/16', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'Y', date: '2018/06/16', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'Z', date: '2018/06/30', amount: '+45.00', currency: 'USD'),
      build(:transaction, account: 'Ignore', category: 'X', date: '2018/07/18', amount: '+25.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'Ignore', date: '2018/06/14', amount: '-50.00', currency: 'USD')
    ]
  end

  before do
    allow(CONFIG).to receive(:exclusions).and_return(accounts: ['Ignore'], categories: ['Ignore'])
    allow(CONFIG).to receive(:default_currency).and_return('USD')
  end

  describe '#period' do
    subject { report.period }

    let(:result) do
      {
        values: [
          {income: Money.new(240 * 100, 'BBD'), expense: Money.new(-260 * 100, 'BBD')},
          {income: Money.new(120 * 100, 'USD'), expense: Money.new(-130 * 100, 'USD')},
        ],
        percentage: -108.33
      }
    end

    it { is_expected.to eq result }
  end

  describe '#total' do
    subject { report.total }

    let(:result) { {values: [Money.new(-120 * 100, 'BBD'), Money.new(-60 * 100, 'USD')], percentage: -20.0} }

    it { is_expected.to eq result }

    context 'when there are excluded categories for expense' do
      context 'when affected transactions are expenses' do
        let(:options) { {categories: ['Y']} }

        it { is_expected.to eq result }
      end

      context 'when affected transactions are incomes' do
        let(:options) { {categories: ['Z']} }

        it { is_expected.to eq result }
      end
    end

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq({}) }
    end

    context 'when there is no expense' do
      let(:ledger_content) do
        [build(:transaction, date: '2018/07/15', amount: '+75.00', currency: 'USD')]
      end

      it { is_expected.to eq(values: [Money.new(75 * 100, 'USD')], percentage: BigDecimal::INFINITY) }
    end

    context 'when there is no income' do
      let(:ledger_content) do
        [build(:transaction, date: '2018/07/15', amount: '-75.00', currency: 'USD')]
      end

      it { is_expected.to eq(values: [Money.new(-75 * 100, 'USD')], percentage: -BigDecimal::INFINITY) }
    end

    context 'when calculating percentage' do
      let(:options) { {from: Date.new(2018, 1, 1)} }

      context 'when there is more income than expense' do
        let(:ledger_content) do
          [
            build(:transaction, date: '2018/07/15', amount: '+300.00', currency: 'USD'),
            build(:transaction, date: '2018/06/20', amount: '+150.00', currency: 'USD'),
            build(:transaction, date: '2018/06/21', amount: '-75.00', currency: 'USD'),
            build(:transaction, date: '2018/07/14', amount: '-75.00', currency: 'USD')
          ] + [extra]
        end

        context 'current is positive' do
          context 'when the current is less than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '+100.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(400 * 100, 'USD')], percentage: 300.0) }
          end

          context 'when the current is more than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '+800.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(1100 * 100, 'USD')], percentage: 37.5) }
          end
        end

        context 'current is negative' do
          context 'when the current is less than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '-50.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(250 * 100, 'USD')], percentage: 600.0) }
          end

          context 'when the current is more than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '-1000.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(-700 * 100, 'USD')], percentage: 30.0) }
          end
        end
      end

      context 'when there is more expense than income' do
        let(:ledger_content) do
          [
            build(:transaction, date: '2018/07/15', amount: '+100.00', currency: 'USD'),
            build(:transaction, date: '2018/06/21', amount: '-100.00', currency: 'USD'),
            build(:transaction, date: '2018/07/14', amount: '-150.00', currency: 'USD')
          ] + [extra]
        end

        context 'current is positive' do
          context 'when the current is less than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '50.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(-100 * 100, 'USD')], percentage: -300.0) }
          end

          context 'when the current is more than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '1000.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(850 * 100, 'USD')], percentage: -15.0) }
          end
        end

        context 'current is negative' do
          context 'when the current is less than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '-50.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(-200 * 100, 'USD')], percentage: -300.0) }
          end

          context 'when the current is more than net result' do
            let(:extra) { build(:transaction, date: '2017/06/20', amount: '-300.00', currency: 'USD') }

            it { is_expected.to eq(values: [Money.new(-450 * 100, 'USD')], percentage: -50.0) }
          end
        end
      end
    end
  end
end
