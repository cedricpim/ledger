RSpec.describe Ledger::Filters::Investment do
  subject(:filter) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    subject { filter.call(entry) }

    let(:entry) { build(:transaction, category: 'investment') }

    before { allow(CONFIG).to receive(:investments).and_return(['Investment']) }

    it { is_expected.to eq true }

    context 'when category is not an investment one' do
      before { allow(CONFIG).to receive(:investments).and_return(['x']) }

      it { is_expected.to eq false }
    end
  end
end
