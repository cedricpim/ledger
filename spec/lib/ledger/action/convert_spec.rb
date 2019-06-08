RSpec.describe Ledger::Action::Convert do
  subject(:action) { described_class.new }

  describe '#call', :streaming do
    let(:base) { build_list(:transaction, 2) }
    let(:transaction) { build(:transaction, currency: :EUR) }
    let(:ledger_content) { base + [transaction] }

    let(:result) { RSpecHelper.build_result(Ledger::Transaction, *base, transaction.exchange_to(:USD)) }

    it 'converts transactions that differ from main account currency' do
      expect { action.call }.to change { ledger.tap(&:rewind).read }.to(result + "\n")
    end
  end
end
