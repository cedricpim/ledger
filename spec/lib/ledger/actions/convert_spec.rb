RSpec.describe Ledger::Actions::Convert do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:base) { build_list(:transaction, 2) }
    let(:transaction) { build(:transaction, currency: :EUR) }
    let(:ledger_content) { base + [transaction] }

    let(:result) { RSpecHelper.build_result(Ledger::Transaction, *base, transaction.exchange_to(:USD)) }

    it 'converts transactions that differ from main account currency' do
      expect { action.call }.to change { original(:ledger) }.to(result)
    end
  end
end
