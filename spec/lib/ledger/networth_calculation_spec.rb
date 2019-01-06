RSpec.describe Ledger::NetworthCalculation do
  subject(:calculation) { described_class.new(investments, current, currency) }

  let(:investments) do
    [
      t(category: 'Investment', amount: 1, currency: 'USD', date: '2019-01-04', description: 'ISINA - 2'),
      t(category: 'Investment', amount: 1, currency: 'USD', date: '2019-01-02', description: 'ISINA'),
      t(category: 'Investment', amount: 1, currency: 'USD', date: '2019-01-05', description: 'ISINB - 10'),
      t(category: 'Investment', amount: 1, currency: 'USD', date: '2019-01-03', description: 'ISINC - 2'),
      t(category: 'Investment', amount: 1, currency: 'USD', date: '2019-01-04', description: 'ISINC - 2'),
      t(category: 'Something', amount: 1, currency: 'USD', date: '2019-01-04', description: 'Else')
    ]
  end

  let(:current) { Money.new('1000', 'USD') }
  let(:currency) { 'USD' }

  before { allow(Date).to receive(:today).and_return('2019-01-04') }

  let(:quotes) do
    [
      instance_double('Ledger::API::JustETF', quote: Money.new('5000', 'USD'), title: 'A'),
      instance_double('Ledger::API::JustETF', quote: Money.new('500', 'USD'), title: 'B'),
      instance_double('Ledger::API::JustETF', quote: Money.new('50000', 'USD'), title: 'C')
    ]
  end

  describe '#networth' do
    subject { calculation.networth }

    let(:amount) { Money.new('221000', currency) }
    let(:investment) { Money.new('220000', currency) }

    let(:valuations) do
      {
        'A' => Money.new('15000', currency),
        'B' => Money.new('5000', currency),
        'C' => Money.new('200000', currency)
      }
    end

    let(:attributes) do
      {date: '2019-01-04', invested: Money.new(200, currency), investment: investment.to_s, amount: amount.to_s, currency: currency}
    end

    before do
      allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINA').and_return(quotes[0])
      allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINB').and_return(quotes[1])
      allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINC').and_return(quotes[2])
    end

    it { is_expected.to eq Ledger::Networth.new(attributes) }

    context 'valuations' do
      subject { calculation.networth.valuations }

      it { is_expected.to eq valuations }
    end

    context 'when JustETF raises an exception' do
      before { allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINA').and_raise(StandardError) }

      specify { expect { subject }.to raise_error(StandardError) }
    end

    context 'when currency is different' do
      let(:currency) { 'EUR' }
      let(:investment) { Money.new('189597', currency) }
      let(:amount) { Money.new('190459', currency) }

      let(:attributes) do
        {date: '2019-01-04', invested: Money.new(200, currency), investment: investment.to_s, amount: amount.to_s, currency: currency}
      end

      it { is_expected.to eq Ledger::Networth.new(attributes) }
    end
  end
end
