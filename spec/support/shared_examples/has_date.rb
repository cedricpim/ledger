RSpec.shared_examples 'has date' do
  describe '#parsed_date' do
    subject { described_class.new(attrs).parsed_date }

    let(:attrs) { {date: date} }

    context 'when date provided is a String' do
      let(:date) { '21/07/2018' }

      it { is_expected.to eq Date.new(2018, 7, 21) }
    end

    context 'when date provided is not a String' do
      let(:date) { Date.new(2018, 7, 21) }

      it { is_expected.to eq date }
    end
  end
end
