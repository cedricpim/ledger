RSpec.describe Ledger::Networth do
  subject(:entry) { described_class.new(attrs) }

  let(:attrs) { {} }

  it_behaves_like 'has date'
  it_behaves_like 'has money', with_investment: true

  describe '#to_file' do
    subject { described_class.new(attrs).to_file }

    let(:attrs) { {date: '21/07/2018', invested: Money.new('300', 'USD'), investment: '-5.00', amount: '-10.00', currency: 'USD'} }

    it { is_expected.to eq attrs.merge(invested: '+3.00').values.join(',') }
  end
end
