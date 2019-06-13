RSpec.describe Ledger::Filters::IncludeCategory do
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

      context 'when the type is :networth' do
        let(:type) { :networth }

        it { is_expected.to eq true }
      end
    end
  end
end
