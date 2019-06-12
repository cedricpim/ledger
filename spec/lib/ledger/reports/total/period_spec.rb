RSpec.describe Ledger::Reports::Total::Period, :streaming do
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

    context 'when there are excluded categories for expense' do
      context 'when affected transactions are expenses' do
        let(:options) { {categories: ['Y']} }

        let(:result) do
          {
            values: [
              {income: Money.new(140 * 100, 'BBD'), expense: Money.new(-160 * 100, 'BBD')},
              {income: Money.new(70 * 100, 'USD'), expense: Money.new(-80 * 100, 'USD')}
            ],
            percentage: -114.29
          }
        end

        it { is_expected.to eq result }
      end

      context 'when affected transactions are incomes' do
        let(:options) { {categories: ['Z']} }

        let(:result) do
          {
            values: [
              {income: Money.new(150 * 100, 'BBD'), expense: Money.new(-170 * 100, 'BBD')},
              {income: Money.new(75 * 100, 'USD'), expense: Money.new(-85 * 100, 'USD')}
            ],
            percentage: -113.33
          }
        end

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

      let(:result) do
        {
          values: [{income: Money.new(75 * 100, 'USD'), expense: Money.new(0, 'USD')}],
          percentage: BigDecimal::INFINITY
        }
      end

      it { is_expected.to eq result }
    end

    context 'when there is no income' do
      let(:ledger_content) do
        [build(:transaction, date: '2018/07/15', amount: '-75.00', currency: 'USD')]
      end

      let(:result) do
        {
          values: [{income: Money.new(0, 'USD'), expense: Money.new(-75 * 100, 'USD')}],
          percentage: -BigDecimal::INFINITY
        }
      end

      it { is_expected.to eq result }
    end

    context 'when caculating percentage' do
      context 'when there is more income than expense' do
        context 'when there is more than two times' do
          let(:ledger_content) do
            [
              build(:transaction, date: '2018/05/20', amount: 60, currency: 'USD'),
              build(:transaction, date: '2018/03/20', amount: 120, currency: 'USD'),
              build(:transaction, date: '2018/02/20', amount: -60, currency: 'USD')
            ]
          end

          let(:result) do
            {values: [{income: Money.new(180 * 100, 'USD'), expense: Money.new(-60 * 100, 'USD')}], percentage: 66.67}
          end

          it { is_expected.to eq result }
        end

        context 'when there is less than two times' do
          let(:ledger_content) do
            [
              build(:transaction, date: '2018/05/20', amount: 60, currency: 'USD'),
              build(:transaction, date: '2018/03/20', amount: 20, currency: 'USD'),
              build(:transaction, date: '2018/02/20', amount: -60, currency: 'USD')
            ]
          end

          let(:result) do
            {values: [{income: Money.new(80 * 100, 'USD'), expense: Money.new(-60 * 100, 'USD')}], percentage: 25.0}
          end

          it { is_expected.to eq result }
        end
      end

      context 'when there is more expense than income' do
        context 'when there is more than two times' do
          let(:ledger_content) do
            [
              build(:transaction, date: '2018/05/20', amount: 100, currency: 'USD'),
              build(:transaction, date: '2018/03/20', amount: -100, currency: 'USD'),
              build(:transaction, date: '2018/02/20', amount: -150, currency: 'USD')
            ]
          end

          let(:result) do
            {values: [{income: Money.new(100 * 100, 'USD'), expense: Money.new(-250 * 100, 'USD')}], percentage: -250.0}
          end

          it { is_expected.to eq result }
        end

        context 'when there is less than two times' do
          let(:ledger_content) do
            [
              build(:transaction, date: '2018/05/20', amount: 100, currency: 'USD'),
              build(:transaction, date: '2018/03/20', amount: -100, currency: 'USD'),
              build(:transaction, date: '2018/02/20', amount: -75, currency: 'USD')
            ]
          end

          let(:result) do
            {values: [{income: Money.new(100 * 100, 'USD'), expense: Money.new(-175 * 100, 'USD')}], percentage: -175.0}
          end

          it { is_expected.to eq result }
        end
      end
    end
  end
end
