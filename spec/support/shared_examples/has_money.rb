RSpec.shared_examples 'has money' do
  describe '#money' do
    subject { described_class.new(attrs).money }

    let(:attrs) { {amount: '+10', currency: 'USD'} }

    it { is_expected.to eq Money.new(1000) }
  end

  describe '#expense?' do
    subject { described_class.new(attrs) }

    let(:attrs) { {amount: '-10', currency: 'USD'} }

    it { is_expected.to be_expense }
  end

  describe '#income?' do
    subject { described_class.new(attrs) }

    let(:attrs) { {amount: '+10', currency: 'USD'} }

    it { is_expected.to be_income }
  end

  describe '#exchange_to' do
    subject { described_class.new(attrs).exchange_to('EUR') }

    %w[+ -].each do |signal|
      context "for signal #{signal}" do
        let(:attrs) { {amount: "#{signal}10", currency: 'USD'} }
        let(:result) { described_class.new(amount: "#{signal}8.62", currency: 'EUR') }

        it { is_expected.to eq result }

        context 'for money instance' do
          subject { described_class.new(attrs).exchange_to('EUR').money }

          it { is_expected.to eq result.money }
        end
      end
    end
  end
end
