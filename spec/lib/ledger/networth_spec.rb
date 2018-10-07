RSpec.describe Ledger::Networth do
  subject(:networth) { described_class.new(attrs) }

  let(:attrs) { {} }

  describe '#parsed_date' do
    subject { networth.parsed_date }

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

  describe '#money' do
    subject { networth.money }

    let(:attrs) { {amount: '+10', currency: 'USD'} }

    it { is_expected.to eq Money.new(1000) }
  end

  describe '#to_file' do
    subject { networth.to_file }

    let(:attrs) { {date: '21/07/2018', amount: '-10.00', currency: 'USD'} }

    it { is_expected.to eq attrs.values.join(',') + "\n" }
  end

  describe '#exchange_to' do
    subject { networth.exchange_to('EUR') }

    %w[+ -].each do |signal|
      context "for signal #{signal}" do
        let(:attrs) { {amount: "#{signal}10", currency: 'USD'} }
        let(:result) { described_class.new(amount: "#{signal}8.62", currency: 'EUR') }

        it { is_expected.to eq result }

        context 'for money instance' do
          subject { networth.exchange_to('EUR').money }

          it { is_expected.to eq result.money }
        end
      end
    end
  end
end
