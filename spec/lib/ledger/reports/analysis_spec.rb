RSpec.describe Ledger::Reports::Analysis, :streaming do
  subject(:report) { described_class.new(options.merge(category: category)) }

  let(:options) { {} }
  let(:category) { 'C' }

  # rubocop:disable Metrics/LineLength
  let(:ledger_content) do
    [
      build(:transaction, account: 'A', category: 'C', description: 'X', date: '2017/06/20', amount: '-120.00', currency: 'BBD'),
      build(:transaction, account: 'A', category: 'C', description: 'X', date: '2018/07/14', amount: '-20.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'C', description: 'Y', date: '2018/07/15', amount: '-20.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'C', description: 'Y', date: '2018/07/13', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'B', category: 'D', date: '2018/07/18', amount: '-100.00', currency: 'USD'),
      build(:transaction, account: 'Ignore', category: 'C', date: '2018/07/18', amount: '-50.00', currency: 'USD'),
      build(:transaction, account: 'A', category: 'Ignore', date: '2018/06/14', amount: '-50.00', currency: 'USD')
    ]
  end
  # rubocop:enable Metrics/LineLength

  before { allow(CONFIG).to receive(:exclusions).and_return(accounts: ['Ignore'], categories: ['Ignore']) }

  describe '#data' do
    subject { report.data }

    let(:result) do
      {
        'A' => [
          {title: 'X', amount: 2, value: Money.new(-160 * 100, 'BBD'), percentages: [80.0, 32.0]},
          {title: 'Y', amount: 1, value: Money.new(-20 * 100, 'USD'), percentages: [20.0, 8.0]},
          {title: 'C', amount: 3, value: Money.new(-200 * 100, 'BBD'), percentages: [40.0, 40.0]}
        ],
        'B' => [
          {title: 'Y', amount: 1, value: Money.new(-50 * 100, 'USD'), percentages: [100.00, 20.0]},
          {title: 'C', amount: 1, value: Money.new(-50 * 100, 'USD'), percentages: [20.0, 20.0]}
        ]
      }
    end

    it { is_expected.to eq result }

    context 'with currency' do
      let(:options) { {currency: 'USD'} }

      let(:result) do
        super().merge(
          'A' => [
            {title: 'X', amount: 2, value: Money.new(-80 * 100, 'USD'), percentages: [80.0, 32.0]},
            {title: 'Y', amount: 1, value: Money.new(-20 * 100, 'USD'), percentages: [20.0, 8.0]},
            {title: 'C', amount: 3, value: Money.new(-100 * 100, 'USD'), percentages: [40.0, 40.0]}
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
            {title: 'X', amount: 1, value: Money.new(-20 * 100, 'USD'), percentages: [50.0, 10.53]},
            {title: 'Y', amount: 1, value: Money.new(-20 * 100, 'USD'), percentages: [50.0, 10.53]},
            {title: 'C', amount: 2, value: Money.new(-40 * 100, 'USD'), percentages: [21.05, 16.0]}
          ],
          'B' => [
            {title: 'Y', amount: 1, value: Money.new(-50 * 100, 'USD'), percentages: [100.00, 26.32]},
            {title: 'C', amount: 1, value: Money.new(-50 * 100, 'USD'), percentages: [26.32, 20.0]}
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
          {title: 'X', amount: 2, value: Money.new(-160 * 100, 'BBD'), percentages: [53.33, 32.0]},
          {title: 'Y', amount: 2, value: Money.new(-70 * 100, 'USD'), percentages: [46.67, 28.0]},
          {title: 'C', amount: 4, value: Money.new(-300 * 100, 'BBD'), percentages: [60.0, 60.0]}
        ]
      }
    end

    it { is_expected.to eq result }

    context 'with currency' do
      let(:options) { {currency: 'USD'} }

      let(:result) do
        {
          'Global' => [
            {title: 'X', amount: 2, value: Money.new(-80 * 100, 'USD'), percentages: [53.33, 32.0]},
            {title: 'Y', amount: 2, value: Money.new(-70 * 100, 'USD'), percentages: [46.67, 28.0]},
            {title: 'C', amount: 4, value: Money.new(-150 * 100, 'USD'), percentages: [60.0, 60.0]}
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
            {title: 'Y', amount: 2, value: Money.new(-70 * 100, 'USD'), percentages: [77.78, 36.84]},
            {title: 'X', amount: 1, value: Money.new(-20 * 100, 'USD'), percentages: [22.22, 10.53]},
            {title: 'C', amount: 3, value: Money.new(-90 * 100, 'USD'), percentages: [47.37, 36.0]}
          ]
        }
      end

      it { is_expected.to eq result }
    end
  end
end
