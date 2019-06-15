RSpec.describe Ledger::Actions::Networth do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:options) { {currency: 'USD'} }

    let(:ledger_content) do
      [
        build(:transaction, date: '2019-06-07', amount: '+10.00'),
        build(:transaction, date: '2019-06-07', category: 'Investment', amount: '+10.00')
      ]
    end

    let(:networth_content) do
      [build(:networth, date: '2019-06-07', invested: '+0.00', investment: '+5.00', amount: '+10.00')]
    end

    let(:data) do
      {
        date: '2019-06-08',
        invested: 0,
        investment: Money.new(900 * 100, options[:currency]),
        amount: Money.new(905 * 100, options[:currency]),
        currency: options[:currency]
      }
    end

    let(:result) do
      RSpecHelper.build_result(
        Ledger::Networth,
        build(:networth, date: '2019-06-07', invested: '+10.00', investment: '+5.00', amount: '+10.00'),
        build(:networth, date: '2019-06-08', invested: '+0.00', investment: '+900.00', amount: '+905.00')
      )
    end

    it 'recalculates existing networths and add the new one' do
      expect { action.call(data) }.to change { networth.tap(&:rewind).read }.to(result)
    end

    context 'when a different currency is given' do
      let(:options) { {currency: 'EUR'} }

      let(:result) do
        RSpecHelper.build_result(
          Ledger::Networth,
          build(:networth, currency: 'EUR', invested: '8.62', investment: '4.31', amount: '8.62', date: '2019-06-07'),
          build(:networth, currency: 'EUR', invested: '+0.00', investment: '+900.00', amount: '+905.00', date: '2019-06-08')
        )
      end

      it 'recalculates existing networths and add the new one' do
        expect { action.call(data) }.to change { networth.tap(&:rewind).read }.to(result)
      end
    end
  end
end
