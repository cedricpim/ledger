RSpec.describe Ledger::Transaction do
  subject(:transaction) { described_class.new(attrs) }

  let(:attrs) { {} }

  describe '#parsed_date' do
    subject { transaction.parsed_date }

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
    subject { transaction.money }

    let(:attrs) { {amount: '+10', currency: 'USD'} }

    it { is_expected.to eq Money.new(1000) }
  end

  describe '#expense?' do
    let(:attrs) { {amount: '-10', currency: 'USD'} }

    it { is_expected.to be_expense }
  end

  describe '#income?' do
    let(:attrs) { {amount: '+10', currency: 'USD'} }

    it { is_expected.to be_income }
  end

  describe '#to_ledger' do
    subject { transaction.to_ledger }

    let(:attrs) do
      {
        account: 'Account',
        date: '21/07/2018',
        category: 'Category',
        description: 'Description',
        venue: 'Venue',
        amount: '-10.00',
        currency: 'USD',
        processed: true,
        travel: 'Travel'
      }
    end

    it { is_expected.to eq attrs.values.join(',') + "\n" }
  end

  describe '#exchange_to' do
    subject { transaction.exchange_to('EUR') }

    %w[+ -].each do |signal|
      context "for signal #{signal}" do
        let(:attrs) { {account: 'A', amount: "#{signal}10", currency: 'USD'} }
        let(:result) { described_class.new(account: 'A', amount: "#{signal}8.62", currency: 'EUR') }

        it { is_expected.to eq result }

        context 'for money instance' do
          subject { transaction.exchange_to('EUR').money }

          it { is_expected.to eq result.money }
        end
      end
    end
  end
end
