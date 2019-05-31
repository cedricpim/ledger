RSpec.describe Ledger::Action::Book do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    let(:transaction) { build(:transaction) }
    let(:options) { {transaction: transaction.to_h.values} }
    let(:repository) { instance_double('Ledger::Repository') }

    it 'adds the resulting transaction to Repository' do
      expect(Ledger::Repository).to receive(:new).and_return(repository)
      expect(repository).to receive(:add).with(transaction)

      action.call
    end
  end
end
