RSpec.describe Ledger::Reports::Trip, :streaming do
  subject(:report) { described_class.new(options) }

  let(:options) { {} }

  let(:ledger_content) do
    [
      build(:transaction, category: 'C', amount: '-120.00', currency: 'BBD', travel: 'X'),
      build(:transaction, category: 'C', amount: '-20.00', currency: 'USD', travel: 'X'),
      build(:transaction, category: 'D', amount: '-140.00', currency: 'USD', travel: 'Y'),
      build(:transaction, category: 'E', amount: '-50.00', currency: 'USD'),
      build(:transaction, category: 'D', amount: '-100.00', currency: 'USD', travel: 'Y'),
      build(:transaction, account: 'Ignore', category: 'D', amount: '-150.00', currency: 'USD', travel: 'X'),
      build(:transaction, category: 'Ignore', amount: '-50.00', currency: 'USD', travel: 'Y')
    ]
  end

  before { allow(CONFIG).to receive(:exclusions).and_return(accounts: ['Ignore'], categories: ['Ignore']) }

  describe '#data' do
    subject { report.data }

    let(:options) { {trip: 'x', currency: 'USD'} }

    let(:result) do
      {
        'X' => [
          {title: 'D', value: Money.new(-150 * 100, 'USD'), percentage: 65.22},
          {title: 'C', value: Money.new(-80 * 100, 'USD'), percentage: 34.78},
          {title: 'Total', value: Money.new(-230 * 100, 'USD'), percentage: nil}
        ]
      }
    end

    it { is_expected.to eq result }

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq({}) }
    end

    context 'when there is no trip defined' do
      let(:options) { {} }

      it { is_expected.to eq({}) }
    end
  end

  describe '#global' do
    subject { report.global }

    let(:options) { {currency: 'USD'} }

    let(:result) do
      {
        'Global' => [
          {title: 'X', value: Money.new(-230 * 100, 'USD'), percentage: 48.94},
          {title: 'Y', value: Money.new(-240 * 100, 'USD'), percentage: 51.06},
          {title: 'Total', value: Money.new(-470 * 100, 'USD'), percentage: nil}
        ]
      }
    end

    it { is_expected.to eq result }

    context 'when there are no transactions' do
      let(:ledger_content) { [] }

      it { is_expected.to eq({}) }
    end
  end
end
