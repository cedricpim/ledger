RSpec.describe Ledger::Networth do
  subject(:networth_entry) { build(:networth, attrs) }

  let(:attrs) { {} }

  it_behaves_like 'has date'
  it_behaves_like 'has money', true

  describe '#to_file' do
    subject { networth_entry.to_file }

    let(:attrs) { {date: '21/07/2018', invested: '+3.00', investment: '-5.00', amount: '-10.00', currency: 'USD', id: ''} }

    it { is_expected.to eq attrs.values.join(',') }
  end

  describe '#valid?' do
    subject { networth_entry.valid? }

    it { is_expected.to be_truthy }

    %w[date amount investment invested].each do |field|
      context "when #{field} is not parseable" do
        before { networth_entry.public_send(:"#{field}=", 'not parseable') }

        it { is_expected.to be_falsey }
      end
    end
  end
end
