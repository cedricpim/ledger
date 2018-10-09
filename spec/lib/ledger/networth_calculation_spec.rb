RSpec.describe Ledger::NetworthCalculation do
  subject(:calculation) { described_class.new(investments, current, currency) }

  let(:investments) do
    [
      t(category: 'Investment', description: 'ISINA - 2'),
      t(category: 'Investment', description: 'ISINA'),
      t(category: 'Investment', description: 'ISINB - 10'),
      t(category: 'Investment', description: 'ISINC - 2'),
      t(category: 'Investment', description: 'ISINC - 2'),
      t(category: 'Something', description: 'Else')
    ]
  end

  let(:current) { Money.new(1000, 'USD') }
  let(:currency) { 'USD' }

  let(:quotes) do
    [
      instance_double('Ledger::API::JustETF', quote: Money.new(5000, 'USD')),
      instance_double('Ledger::API::JustETF', quote: Money.new(500, 'USD')),
      instance_double('Ledger::API::JustETF', quote: Money.new(50000, 'USD'))
    ]
  end

  describe '#networth' do
    subject { calculation.networth }

    let(:amount) { Money.new('221000', 'USD') }

    before do
      allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINA').and_return(quotes[0])
      allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINB').and_return(quotes[1])
      allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINC').and_return(quotes[2])
    end

    it { is_expected.to eq Ledger::Networth.new(date: Date.today.to_s, amount: amount.to_s, currency: currency) }

    context 'when JustETF raises an exception' do
      before { allow(Ledger::API::JustETF).to receive(:new).with(isin: 'ISINA').and_raise(StandardError) }

      specify { expect { subject }.to raise_error(StandardError) }
    end

    context 'when currency is different' do
      let(:currency) { 'EUR' }

      let(:amount) { Money.new('190459', 'EUR') }

      it { is_expected.to eq Ledger::Networth.new(date: Date.today.to_s, amount: amount.to_s, currency: currency) }
    end
  end
end
