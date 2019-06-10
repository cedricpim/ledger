RSpec.describe Ledger::Filter do
  subject(:filter) { described_class.new(entries, filters: filters, currency: currency) }

  let(:entries) { [] }
  let(:filters) { [] }
  let(:currency) { nil }

  describe '#call' do
    subject { filter.call }

    let(:entries) { [build(:transaction)] }

    it { is_expected.to eq entries }

    context 'when some filters are provided' do
      let(:filters) { [double(call: true), double(call: true)] }

      it { is_expected.to eq entries }

      context 'when one of the filters return false' do
        let(:filters) { [double(call: false), double(call: true)] }

        it { is_expected.to eq [] }
      end
    end

    context 'when no entries are provided' do
      let(:entries) { [] }

      it { is_expected.to eq [] }
    end

    context 'when a currency is provided' do
      let(:currency) { 'EUR' }

      let(:result) { [build(:transaction, entries.first.to_h.merge(currency: currency, amount: '+8.62'))] }

      it { is_expected.to eq result }
    end
  end
end
