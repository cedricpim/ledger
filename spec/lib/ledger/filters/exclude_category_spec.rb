RSpec.describe Ledger::Filters::ExcludeCategory do
  subject(:filter) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    subject { filter.call(entry) }

    let(:entry) { build(:transaction, category: 'x') }

    it { is_expected.to eq true }

    context 'when categories in options does not contain the category' do
      let(:options) { {categories: ['A', 'B']} }

      it { is_expected.to eq true }
    end

    context 'when categories in options contains the category' do
      let(:options) { {categories: ['A', 'X']} }

      it { is_expected.to eq false }
    end
  end
end
