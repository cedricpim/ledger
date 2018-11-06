RSpec.describe Ledger::NetworthContent do
  subject(:history) do
    described_class.new(networth_entries, Thor::CoreExt::HashWithIndifferentAccess.new(options))
  end

  let(:networth_entries) do
    [
      Ledger::Networth.new(date: '19/07/2018', investment: '+10.00', amount: '-20.00', currency: 'USD'),
      Ledger::Networth.new(date: '20/07/2018', investment: '+40.00', amount: '-20.00', currency: 'USD'),
      Ledger::Networth.new(date: '21/07/2018', investment: '+5.00', amount: '-75.00', currency: 'USD')
    ]
  end
  let(:options) { {} }

  describe '#filtered_networth' do
    subject { history.filtered_networth }

    it { is_expected.to eq networth_entries.slice(0, 3) }

    context 'with currency defined' do
      let(:options) { {currency: 'BBD'} }

      let(:exchanged_networth_entries) do
        [
          Ledger::Networth.new(date: '19/07/2018', investment: '+20.00', amount: '-40.00', currency: 'BBD'),
          Ledger::Networth.new(date: '20/07/2018', investment: '+80.00', amount: '-40.00', currency: 'BBD'),
          Ledger::Networth.new(date: '21/07/2018', investment: '+10.00', amount: '-150.00', currency: 'BBD')
        ]
      end

      it { is_expected.to eq exchanged_networth_entries }
    end

    context 'within a period' do
      let(:options) do
        {from: Date.new(2018, 7, 20), till: Date.new(2018, 7, 20), year: 2017, month: 7}
      end

      it { is_expected.to eq networth_entries.slice(1, 1) }

      context 'without from param' do
        before { options.delete(:from) }

        it { is_expected.to eq networth_entries.slice(0, 2) }
      end

      context 'without till param' do
        before { options.delete(:till) }

        it { is_expected.to eq networth_entries.slice(1, 2) }
      end

      context 'without till and from param' do
        before do
          options.delete(:till)
          options.delete(:from)
        end

        it { is_expected.to eq [] }
      end

      context 'without till and from and year param' do
        before do
          options.delete(:till)
          options.delete(:from)
          options.delete(:year)
        end

        it { is_expected.to eq networth_entries }
      end

      context 'without till and from and month param' do
        before do
          options.delete(:till)
          options.delete(:from)
          options.delete(:month)
        end

        it { is_expected.to eq networth_entries }
      end
    end
  end
end
