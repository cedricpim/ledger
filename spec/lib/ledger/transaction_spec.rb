RSpec.describe Ledger::Transaction do
  it_behaves_like 'has date'
  it_behaves_like 'has money', with_investment: false

  describe '#to_file' do
    subject { described_class.new(attrs).to_file }

    let(:attrs) do
      {
        account: 'Account',
        date: '21/07/2018',
        category: 'Category',
        description: 'Description',
        venue: 'Venue',
        amount: '-10.00',
        currency: 'USD',
        travel: 'Travel'
      }
    end

    it { is_expected.to eq attrs.values.join(',') }
  end

  describe '#isin' do
    subject { described_class.new(attrs).isin }

    let(:isin) { '123AAA4' }
    let(:attrs) { {account: 'Account', category: 'investment', description: "#{isin} - 10"} }

    it { is_expected.to eq isin }

    context 'when transaction is not an investment' do
      let(:attrs) { super().merge(category: 'other') }

      it { is_expected.to be_nil }
    end
  end

  describe '#shares' do
    subject { described_class.new(attrs).shares }

    let(:number) { 10 }
    let(:attrs) { {account: 'Account', category: 'investment', description: "ISIN - #{number}"} }

    it { is_expected.to eq number }

    context 'when transaction is not an investment' do
      let(:attrs) { super().merge(category: 'other') }

      it { is_expected.to eq 0 }
    end

    context 'when transaction does not have any share defined' do
      let(:attrs) { super().merge(description: 'ISIN') }

      it { is_expected.to eq 1 }
    end
  end

  describe '#valid?' do
    subject { entry.valid? }

    let(:entry) { build(:transaction) }

    it { is_expected.to be_truthy }

    %w[date amount].each do |field|
      context "when #{field} is not parseable" do
        before { entry.public_send(:"#{field}=", 'not parseable') }

        it { is_expected.to be_falsey }
      end
    end

    %w[account category].each do |field|
      context "when #{field} is nil" do
        before { entry.public_send(:"#{field}=", nil) }

        it { is_expected.to be_falsey }
      end

      context "when #{field} is empty" do
        before { entry.public_send(:"#{field}=", '') }

        it { is_expected.to be_falsey }
      end
    end
  end
end
