RSpec.describe Ledger::Action::Book do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:transaction) { build(:transaction) }
    let(:options) { {transaction: transaction.to_h.values} }

    it 'adds the resulting transaction to ledger' do
      expect { action.call }.to change { ledger.tap(&:rewind).read }.to(transaction.to_file + "\n")
    end
  end
end
