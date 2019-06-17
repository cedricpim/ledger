RSpec.describe Ledger::Filters::Trip do
  subject(:filter) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    subject { filter.call(entry) }

    let(:trip) { 'Country' }
    let(:entry) { build(:transaction, trip: trip) }

    it { is_expected.to eq true }

    context 'when trip is nil' do
      let(:trip) { nil }

      it { is_expected.to eq false }
    end

    context 'when trip is empty' do
      let(:trip) { '' }

      it { is_expected.to eq false }
    end

    context 'when option trip is present' do
      let(:options) { {trip: 'City'} }

      it { is_expected.to eq false }

      context 'when trip includes the option trip' do
        let(:trip) { '[2019.05] City - Awesome' }

        it { is_expected.to eq true }
      end
    end
  end
end
