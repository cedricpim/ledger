RSpec.describe Ledger::Filters::Trip do
  subject(:filter) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    subject { filter.call(entry) }

    let(:travel) { 'Country' }
    let(:entry) { build(:transaction, travel: travel) }

    it { is_expected.to eq true }

    context 'when travel is nil' do
      let(:travel) { nil }

      it { is_expected.to eq false }
    end

    context 'when travel is empty' do
      let(:travel) { '' }

      it { is_expected.to eq false }
    end

    context 'when option trip is present' do
      let(:options) { {trip: 'City'} }

      it { is_expected.to eq false }

      context 'when travel includes the option trip' do
        let(:travel) { '[2019.05] City - Awesome' }

        it { is_expected.to eq true }
      end
    end
  end
end
