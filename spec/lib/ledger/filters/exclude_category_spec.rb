RSpec.describe Ledger::Filters::ExcludeCategory do
  subject(:filter) { described_class.new(options, type) }

  let(:options) { {} }

  let(:type) { nil }

  describe '#call' do
    subject { filter.call(entry) }

    let(:type) { :report }

    let(:entry) { build(:transaction, category: 'x') }

    it { is_expected.to eq true }

    context 'when the category provided is the same as the entry' do
      let(:entry) { build(:transaction, category: 'exchange') }

      it { is_expected.to eq false }
    end

    context 'when the type is :networth' do
      let(:entry) { build(:transaction, category: 'exchange') }

      it { is_expected.to eq false }
    end

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
