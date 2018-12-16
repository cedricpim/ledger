RSpec.describe Ledger::Networth do
  subject(:networth) { described_class.new(attrs) }

  let(:attrs) { {} }

  it_behaves_like 'has date'
  it_behaves_like 'has money', with_investment: true

  describe '#to_file' do
    subject { described_class.new(attrs).to_file }

    let(:attrs) { {date: '21/07/2018', investment: '-5.00', amount: '-10.00', currency: 'USD'} }

    it { is_expected.to eq attrs.values.join(',') }
  end

  describe '#list' do
    subject { networth.list }

    let(:attrs) { {amount: '5000', currency: 'USD'} }

    let(:valuations) do
      {
        'ISINA' => Money.new(15_000, 'USD'),
        'ISINB' => Money.new(5000, 'USD'),
        'ISINC' => Money.new(200_000, 'USD')
      }
    end

    let(:result) do
      [
        ['ISINA', '+150.00$', 3.0],
        ['ISINB', '+50.00$', 1.0],
        ['ISINC', '+2,000.00$', 40.0],
        ['Other', '+2,800.00$', 56.0]
      ]
    end

    before { networth.valuations = valuations }

    it { is_expected.to eq result }
  end

  describe '#total' do
    subject { networth.total }

    let(:attrs) { {amount: '5000', currency: 'USD'} }

    let(:result) { ['Total', '+5,000.00$', 100.0] }

    it { is_expected.to eq result }
  end
end
