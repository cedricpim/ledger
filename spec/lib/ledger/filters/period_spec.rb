RSpec.describe Ledger::Filters::Period do
  subject(:filter) { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    subject { filter.call(entry) }

    let(:date) { '2019/06/08' }
    let(:entry) { build(:transaction, date: date) }

    it { is_expected.to eq true }

    context 'when a month and year are defined' do
      let(:options) { {month: 5, year: 2018} }

      it { is_expected.to eq false }

      context 'when the month and year match' do
        let(:options) { {month: 6, year: 2019} }

        it { is_expected.to eq true }
      end

      context 'when the month matches' do
        before { options[:month] = 6 }

        it { is_expected.to eq false }
      end

      context 'when the year matches' do
        before { options[:year] = 2019 }

        it { is_expected.to eq false }
      end

      context 'when month is missing' do
        before { options.delete(:month) }

        it { is_expected.to eq true }
      end

      context 'when year is missing' do
        before { options.delete(:year) }

        it { is_expected.to eq true }
      end
    end

    context 'when from and till are defined' do
      let(:options) { {from: Date.new(2019, 6, 8), till: Date.new(2019, 6, 8)} }

      it { is_expected.to eq true }
    end

    context 'when only from is defined' do
      let(:options) { {from: Date.new(2019, 6, 9)} }

      it { is_expected.to eq false }

      context 'when from includes the date' do
        let(:options) { {from: Date.new(2019, 6, 8)} }

        it { is_expected.to eq true }
      end
    end

    context 'when only till is defined' do
      let(:options) { {till: Date.new(2019, 6, 7)} }

      it { is_expected.to eq false }

      context 'when from includes the date' do
        let(:options) { {till: Date.new(2019, 6, 8)} }

        it { is_expected.to eq true }
      end
    end
  end
end
