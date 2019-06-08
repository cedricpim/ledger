RSpec.describe Ledger::Action::Book do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:transaction) { build(:transaction, travel: '') }
    let(:options) { {transaction: transaction.to_h.values} }

    let(:headers) { RSpecHelper.headers(Ledger::Transaction) }
    let(:ledger_content) { [] }

    let(:result) { RSpecHelper.build_result(Ledger::Transaction, transaction) }

    it 'adds the resulting transaction to ledger' do
      expect { action.call }.to change { ledger.tap(&:rewind).read }.to(result)
    end
  end
end
