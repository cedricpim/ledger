RSpec.describe Ledger::MoneyHelper do
  subject(:helper) { described_class }

  describe '.display' do
    subject { helper.display(money, type: type) }

    let(:type) { :display }

    context 'when money is not an instance of Money' do
      let(:money) { 'something' }

      it { is_expected.to eq '------' }
    end

    %w[+ -].each do |signal|
      context 'when money is an instance of Money' do
        let(:money) { Money.new("#{signal}123456", 'USD') }

        context 'when type is :display' do
          let(:type) { :display }

          it { is_expected.to eq "#{signal}1,234.56$" }
        end

        context 'when type is :ledger' do
          let(:type) { :ledger }

          it { is_expected.to eq "#{signal}1234.56" }
        end
      end
    end
  end

  describe '.percentage' do
    subject { helper.percentage(value, transactions) }

    let(:value) { Money.new(2000, 'USD') }

    let(:transactions) do
      [
        build(:transaction, amount: '+25.00', currency: 'USD'),
        build(:transaction, amount: '+75.00', currency: 'USD'),
        build(:transaction, amount: '-80.00', currency: 'USD')
      ]
    end

    it { is_expected.to eq 20.0 }

    context 'when value is not a Money instance' do
      let(:value) { 'something' }

      it { is_expected.to eq nil }
    end

    context 'when total sum of transactions  is not a Money instance' do
      let(:transactions) { [] }

      it { is_expected.to eq nil }
    end

    context 'when value is negative' do
      let(:value) { Money.new(-2100, 'USD') }

      it { is_expected.to eq 26.25 }
    end
  end

  describe '.display_with_color' do
    subject { helper.display_with_color(value, options) }

    let(:options) { {a: :b} }

    context 'when value is a Money instance' do
      let(:value) { Money.new(123_456, 'USD') }

      it { is_expected.to eq ['1,234.56$', a: :b, color: :green] }
    end

    context 'when value is present' do
      let(:value) { 12.0 }

      it { is_expected.to eq ['12.0%', a: :b, color: :green] }

      context 'when value is negative' do
        let(:value) { -12.0 }

        it { is_expected.to eq ['12.0%', a: :b, color: :red] }
      end
    end

    context 'when value is nil' do
      let(:value) { nil }

      it { is_expected.to eq ['-----', a: :b, color: :black] }
    end

    context 'when value is Infinity' do
      let(:value) { Float::INFINITY }

      it { is_expected.to eq ['100.0%', a: :b, color: :green] }
    end

    context 'when value is -Infinity' do
      let(:value) { Float::INFINITY * -1 }

      it { is_expected.to eq ['100.0%', a: :b, color: :red] }
    end

    context 'when value is NaN' do
      let(:value) { Float::NAN }

      it { is_expected.to eq ['0.0%', a: :b, color: :black] }
    end
  end
end
