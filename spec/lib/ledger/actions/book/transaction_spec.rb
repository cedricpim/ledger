RSpec.describe Ledger::Actions::Book::Transaction do
  subject(:builder) { described_class.new(values: values) }

  let(:values) { nil }

  let(:transaction) { build(:transaction, trip: '') }

  describe '#build!' do
    subject { builder.build! }

    let(:values) { transaction.to_h.values }

    it { is_expected.to eq transaction }

    context 'with values provided from STDIN' do
      let(:values) { nil }

      before do
        expect(Readline).to receive(:readline).and_return(
          transaction.account,
          transaction.date,
          transaction.category,
          '',
          transaction.quantity,
          '',
          transaction.amount,
          transaction.currency,
          ''
        )
      end

      it { is_expected.to eq build(:transaction, description: '', venue: '', trip: '') }
    end
  end
end
