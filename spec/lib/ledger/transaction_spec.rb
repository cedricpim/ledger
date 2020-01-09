RSpec.describe Ledger::Transaction do
  subject(:transaction) { build(:transaction, attrs) }

  let(:attrs) { {} }

  it_behaves_like 'has date'
  it_behaves_like 'has money', false

  describe '#to_file' do
    subject { transaction.to_file }

    let(:attrs) do
      {
        account: 'Account',
        date: '21/07/2018',
        category: 'Category',
        description: 'Description',
        quantity: '2',
        venue: 'Venue',
        amount: '-10.00',
        currency: 'USD',
        trip: 'Trip'
      }
    end

    it { is_expected.to eq attrs.values.join(',') }
  end

  describe '#valid?' do
    subject { transaction.valid? }

    it { is_expected.to be_truthy }

    %w[date amount].each do |field|
      context "when #{field} is not parseable" do
        before { transaction.public_send(:"#{field}=", 'not parseable') }

        it { is_expected.to be_falsey }
      end
    end

    %w[account category].each do |field|
      context "when #{field} is nil" do
        before { transaction.public_send(:"#{field}=", nil) }

        it { is_expected.to be_falsey }
      end

      context "when #{field} is empty" do
        before { transaction.public_send(:"#{field}=", '') }

        it { is_expected.to be_falsey }
      end
    end
  end
end
