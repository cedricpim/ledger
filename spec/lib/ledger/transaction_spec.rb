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
        processed: true,
        travel: 'Travel'
      }
    end

    it { is_expected.to eq attrs.values.join(',') + "\n" }
  end

  describe '#investment?' do
    subject { described_class.new(attrs).investment? }

    let(:attrs) { {account: 'Account', category: 'investment'} }

    it { is_expected.to eq true }

    context 'when category is not an investment one' do
      let(:attrs) { {account: 'Account', category: 'drinks'} }

      it { is_expected.to eq false }
    end
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
end
