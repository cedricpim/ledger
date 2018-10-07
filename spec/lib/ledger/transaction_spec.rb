RSpec.describe Ledger::Transaction do
  it_behaves_like 'has date'
  it_behaves_like 'has money'

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
end
