RSpec.describe Ledger::Networth do
  subject(:networth) { described_class.new(attrs) }

  let(:attrs) { {} }

  it_behaves_like 'has date'
  it_behaves_like 'has money'

  describe '#to_file' do
    subject { described_class.new(attrs).to_file }

    let(:attrs) { {date: '21/07/2018', amount: '-10.00', currency: 'USD'} }

    it { is_expected.to eq attrs.values.join(',') + "\n" }
  end
end
