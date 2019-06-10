RSpec.describe Ledger::Filters::IgnoreAccount do
  subject(:filter) { described_class.new(options, type) }

  let(:options) { {} }

  let(:type) { nil }

  describe '#call' do
    subject { filter.call(entry) }

    let(:type) { :report }

    let(:entry) { build(:transaction, account: 'x') }

    it { is_expected.to eq true }

    context 'when the account provided is the same as the entry' do
      let(:entry) { build(:transaction, account: 'vacation') }

      it { is_expected.to eq false }
    end

    context 'when the type is :networth' do
      let(:entry) { build(:transaction, account: 'vacation') }

      it { is_expected.to eq false }
    end
  end
end
