RSpec.describe Ledger::Filters::Category do
  subject(:filter) { described_class.new(options, category) }

  let(:options) { {} }

  let(:category) { nil }

  describe '#call' do
    subject { filter.call(entry) }

    let(:category) { 'A' }

    let(:entry) { build(:transaction, category: category.downcase) }

    it { is_expected.to eq true }

    context 'when the category provided is not the same as the entry' do
      let(:entry) { build(:transaction, category: category * 2) }

      it { is_expected.to eq false }
    end
  end
end
