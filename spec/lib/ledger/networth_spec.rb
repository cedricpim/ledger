RSpec.describe Ledger::Networth do
  subject(:entry) { described_class.new(attrs) }

  let(:attrs) { {} }

  it_behaves_like 'has date'
  it_behaves_like 'has money', with_investment: true

  describe '#to_file' do
    subject { build(:networth, attrs).to_file }

    let(:attrs) { {date: '21/07/2018', invested: '+3.00', investment: '-5.00', amount: '-10.00', currency: 'USD'} }

    it { is_expected.to eq attrs.merge(invested: '+3.00').values.join(',') }
  end

  describe '#valid?' do
    subject { entry.valid? }

    let(:entry) { build(:networth) }

    it { is_expected.to be_truthy }

    %w[date amount investment invested].each do |field|
      context "when #{field} is not parseable" do
        before { entry.public_send(:"#{field}=", 'not parseable') }

        it { is_expected.to be_falsey }
      end
    end
  end
end
