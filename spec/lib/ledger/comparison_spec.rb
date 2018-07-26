RSpec.describe Ledger::Comparison do
  subject(:comparison) { described_class.new(category, transactions, periods, currency) }

  let(:category) { 'A' }
  let(:transactions) do
    [
      t(category: 'A', date: '19/06/2018', amount: -1, currency: 'USD'),
      t(category: 'A', date: '19/06/2018', amount: -1, currency: 'USD'),
      t(category: 'A', date: '20/07/2018', amount: -1, currency: 'USD'),
      t(category: 'A', date: '21/07/2018', amount: -1, currency: 'USD')
    ]
  end
  let(:periods) do
    [[Date.new(2018, 6, 1), Date.new(2018, 6, 30)], [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]]
  end
  let(:currency) { 'USD' }

  let(:default) { '--' }

  before { allow_any_instance_of(Ledger::Config).to receive(:default_value).and_return(default) }

  describe '#list' do
    subject { comparison.list }

    def build_result(*params)
      result = params.each_slice(2).map { |value, color| [value.to_s, color: color] }

      result.insert(0, ['A', {}])
      result.insert(1, described_class::WHITESPACE.first)
      result.insert(4, described_class::WHITESPACE.first)
      result.insert(6, described_class::WHITESPACE.first)
    end

    def prepare_transactions(*values)
      yield if block_given?

      values.each.with_index { |v, i| transactions[i].amount = v }
    end

    context 'when there was an increase on income' do
      before { prepare_transactions(+1, +2, +2, +3) }

      let(:result) { build_result('3.00$', :green, '5.00$', :green, '2.00$', :green, '66.67%', :green) }

      it { is_expected.to eq result }
    end

    context 'when there was a decrease on income' do
      before { prepare_transactions(+3, +2, +2, +1) }

      let(:result) { build_result('5.00$', :green, '3.00$', :green, '2.00$', :red, '40.0%', :red) }

      it { is_expected.to eq result }
    end

    context 'when there was an increase on expense' do
      before { prepare_transactions(-1, -5, -5, -2) }

      let(:result) { build_result('6.00$', :red, '7.00$', :red, '1.00$', :red, '16.67%', :red) }

      it { is_expected.to eq result }
    end

    context 'when there was a decrease on expense' do
      before { prepare_transactions(-1, -4, -2, -1) }

      let(:result) { build_result('5.00$', :red, '3.00$', :red, '2.00$', :green, '40.0%', :green) }

      it { is_expected.to eq result }
    end

    context 'when there was a change from income to expense' do
      before { prepare_transactions(+2, +3, -2, -2) }

      let(:result) { build_result('5.00$', :green, '4.00$', :red, '9.00$', :red, '180.0%', :red) }

      it { is_expected.to eq result }
    end

    context 'when there was a change from expense to income' do
      before { prepare_transactions(-2, -2, +4, +4) }

      let(:result) { build_result('4.00$', :red, '8.00$', :green, '12.00$', :green, '300.0%', :green) }

      it { is_expected.to eq result }
    end

    context 'when the previous value was non-existent' do
      before { prepare_transactions(+1, +1) { transactions.slice!(0, 2) } }

      let(:result) { build_result('0.00$', :black, '2.00$', :green, '2.00$', :green, default.chop, :black) }

      it { is_expected.to eq result }
    end

    context 'when the next value was non-existent' do
      before { prepare_transactions(+1, +1) { transactions.slice!(2, 2) } }

      let(:result) { build_result('2.00$', :green, '0.00$', :black, '2.00$', :red, default.chop, :black) }

      it { is_expected.to eq result }
    end

    context 'when the previous and the next value were the same' do
      before { prepare_transactions(+1, +1, +1, +1) }

      let(:result) { build_result('2.00$', :green, '2.00$', :green, '0.00$', :black, '0.0%', :black) }

      it { is_expected.to eq result }
    end
  end
end
