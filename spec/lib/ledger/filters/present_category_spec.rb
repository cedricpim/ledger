RSpec.describe Ledger::Filters::PresentCategory do
  subject(:filter) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    subject { filter.call(entry) }

    let(:entry) { build(:transaction, category: 'x') }

    it { is_expected.to eq true }

    context 'when categories in options does not contain the category' do
      let(:options) { {categories: %w[A B]} }

      it { is_expected.to eq true }
    end

    context 'when categories in options contains the category' do
      let(:options) { {categories: %w[A X]} }

      it { is_expected.to eq false }

      context 'when entry does not respond to category' do
        let(:entry) { build(:networth) }

        it { is_expected.to eq true }
      end
    end
  end
end
