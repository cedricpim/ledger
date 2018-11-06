RSpec.shared_examples 'has money' do |with_investment:|
  describe '#money' do
    subject { described_class.new(attrs).money }

    let(:attrs) { {amount: '+10', currency: 'USD'} }

    it { is_expected.to eq Money.new('1000', 'USD') }
  end

  if with_investment
    describe '#valuation' do
      subject { described_class.new(attrs).valuation }

      let(:attrs) { {investment: '+10', currency: 'USD'} }

      it { is_expected.to eq Money.new('1000', 'USD') }
    end
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
        let(:attrs) do
          {amount: "#{signal}10", currency: 'USD'}.tap do |obj|
            obj[:investment] = "#{signal}5" if with_investment
          end
        end
        let(:result) do
          described_class.new(amount: "#{signal}8.62", currency: 'EUR').tap do |obj|
            obj.investment = "#{signal}4.31" if with_investment
          end
        end

        it { is_expected.to eq result }

        context 'for money instance' do
          subject { described_class.new(attrs).exchange_to('EUR').money }

          it { is_expected.to eq result.money }
        end

        if with_investment
          context 'for investment instance' do
            subject { described_class.new(attrs).exchange_to('EUR').investment }

            it { is_expected.to eq result.investment }
          end
        end
      end
    end
  end
end
