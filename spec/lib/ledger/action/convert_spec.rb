RSpec.describe Ledger::Action::Convert do
  subject(:action) { described_class.new }

  describe '#call', :streaming do
    let(:base) do
      ([Ledger::Transaction.members.map(&:capitalize).join(',')] + build_list(:transaction, 2).map(&:to_file)).join("\n")
    end

    let(:ledger_content) { [base, transaction.to_file].join("\n") }
    let(:transaction) { build(:transaction, currency: :EUR) }

    let(:result) { [base, transaction.exchange_to(:USD).to_file].join("\n") }

    it 'converts transactions that differ from main account currency' do
      expect { action.call }.to change { ledger.tap(&:rewind).read }.to(result + "\n")
    end
  end
end