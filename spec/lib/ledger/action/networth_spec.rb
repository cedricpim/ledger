RSpec.describe Ledger::Action::Networth do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:options) { {currency: 'USD'} }

    let(:ledger_content) do
      [
        build(:transaction, date: '2019-06-07', amount: '10'),
        build(:transaction, date: '2019-06-07', category: 'Investment', description: 'ISINA - 2', amount: '10'),
        build(:transaction, date: '2019-06-08', category: 'Investment', description: 'ISINB - 4', amount: '20')
      ]
    end

    let(:networth_content) { [build(:networth, date: '2019-06-07', invested: '0', investment: '5', amount: '10')] }

    let(:result) do
      RSpecHelper.build_result(
        Ledger::Networth,
        build(:networth, date: '2019-06-07', invested: '10', investment: '5', amount: '10'),
        build(:networth, date: '2019-06-08', invested: '20', investment: '120', amount: '160')
      )
    end

    before do
      {'A': '5000', 'B': '500'}.each_pair do |title, value|
        quote = instance_double('Ledger::API::JustETF', quote: Money.new(value, 'USD'), title: title)
        allow(Ledger::API::JustETF).to receive(:new).with(isin: "ISIN#{title}").and_return(quote)
      end
    end

    it 'recalculates existing networths and add the new one' do
      expect { action.call }.to change { networth.tap(&:rewind).read }.to(result)
    end

    context 'when a different currency is given' do
      let(:options) { {currency: 'EUR'} }

      let(:result) do
        RSpecHelper.build_result(
          Ledger::Networth,
          build(:networth, currency: 'EUR', invested: '8.62', investment: '4.31', amount: '8.62', date: '2019-06-07'),
          build(:networth, currency: 'EUR', invested: '17.24', investment: '103.42', amount: '137.90', date: '2019-06-08')
        )
      end

      it 'recalculates existing networths and add the new one' do
        expect { action.call }.to change { networth.tap(&:rewind).read }.to(result)
      end
    end
  end
end
