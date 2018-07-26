RSpec.describe Ledger::TransactionBuilder do
  subject(:builder) { described_class.new(repository) }

  let(:options) { {} }
  let(:repository) { Ledger::Repository.new(options) }

  before { allow(repository).to receive(:load!) }

  describe '#build!' do
    subject { builder.build!.to_ledger }

    let(:keys) { %i[account date category description venue amount currency processed travel] }
    let(:options) { {transaction: ['Account', '21-07-2018', 'Cat', 'Desc', '', '10.0', 'USD', 'yes', '']} }

    let(:result) { t(keys.zip(options[:transaction]).to_h) }

    it { is_expected.to eq result.to_ledger }
  end
end
