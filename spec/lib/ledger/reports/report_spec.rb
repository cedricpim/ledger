RSpec.describe Ledger::Reports::Report, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {} }

  let(:ledger_content) do
    [
      build(:transaction, account: 'A', category: 'C', date: '2017/06/20', amount: '-120.00', currency: 'BBD'),
      build(:transaction, account: 'A', category: 'C', date: '2018/07/14', amount: '-20.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'D', date: '2018/07/15', amount: '-20.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'E', date: '2018/07/13', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'D', date: '2018/07/18', amount: '-100.00', currency: 'USD'),
      build(:transaction, account: 'Ignore', category: 'C', date: '2018/07/18', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'Ignore', date: '2018/06/14', amount: '-50.00', currency: 'USD')
    ]
  end

  before { allow(CONFIG).to receive(:exclusions).and_return(accounts: ['Ignore'], categories: ['Ignore']) }

  describe '#data' do
    subject { report.data }

    let(:result) do
      {
        'A' => [
          {title: 'C', amount: 2, value: Money.new(-160 * 100, 'BBD'), percentage: 32.0},
          {title: 'D', amount: 1, value: Money.new(-20 * 100, 'USD'), percentage: 8.0}
        ],
        'B' => [
          {title: 'D', amount: 1, value: Money.new(-100 * 100, 'USD'), percentage: 40.0},
          {title: 'E', amount: 1, value: Money.new(-50 * 100, 'USD'), percentage: 20.0}
        ]
      }
    end

    it { is_expected.to eq result }

    context 'with currency' do
      let(:options) { {currency: 'USD'} }

      let(:result) do
        super().merge(
          'A' => [
            {title: 'C', amount: 2, value: Money.new(-80 * 100, 'USD'), percentage: 32.0},
            {title: 'D', amount: 1, value: Money.new(-20 * 100, 'USD'), percentage: 8.0}
          ]
        )
      end

      it { is_expected.to eq result }
    end

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq({}) }
    end

    context 'with a defined period' do
      let(:options) { {currency: 'USD', year: 2018, month: 7} }

      let(:result) do
        {
          'A' => [
            {title: 'C', amount: 1, value: Money.new(-20 * 100, 'USD'), percentage: 10.53},
            {title: 'D', amount: 1, value: Money.new(-20 * 100, 'USD'), percentage: 10.53}
          ],
          'B' => [
            {title: 'D', amount: 1, value: Money.new(-100 * 100, 'USD'), percentage: 52.63},
            {title: 'E', amount: 1, value: Money.new(-50 * 100, 'USD'), percentage: 26.32}
          ]
        }
      end

      it { is_expected.to eq result }
    end
  end

  describe '#global' do
    subject { report.global }

    let(:result) do
      {
        'Global' => [
          {title: 'D', amount: 2, value: Money.new(-120 * 100, 'USD'), percentage: 48.0},
          {title: 'C', amount: 2, value: Money.new(-160 * 100, 'BBD'), percentage: 32.0},
          {title: 'E', amount: 1, value: Money.new(-50 * 100, 'USD'), percentage: 20.0}
        ]
      }
    end

    it { is_expected.to eq result }

    context 'with currency' do
      let(:options) { {currency: 'USD'} }

      let(:result) do
        {
          'Global' => [
            {title: 'D', amount: 2, value: Money.new(-120 * 100, 'USD'), percentage: 48.0},
            {title: 'C', amount: 2, value: Money.new(-80 * 100, 'USD'), percentage: 32.0},
            {title: 'E', amount: 1, value: Money.new(-50 * 100, 'USD'), percentage: 20.0}
          ]
        }
      end

      it { is_expected.to eq result }
    end

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq({}) }
    end

    context 'with a defined period' do
      let(:options) { {currency: 'USD', year: 2018, month: 7} }

      let(:result) do
        {
          'Global' => [
            {title: 'D', amount: 2, value: Money.new(-120 * 100, 'USD'), percentage: 63.16},
            {title: 'E', amount: 1, value: Money.new(-50 * 100, 'USD'), percentage: 26.32},
            {title: 'C', amount: 1, value: Money.new(-20 * 100, 'USD'), percentage: 10.53}
          ]
        }
      end

      it { is_expected.to eq result }
    end
  end
end
