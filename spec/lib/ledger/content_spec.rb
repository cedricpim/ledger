RSpec.describe Ledger::Content do
  subject(:content) do
    described_class.new(transactions, Thor::CoreExt::HashWithIndifferentAccess.new(options))
  end

  let(:transactions) do
    [
      t(account: 'A', category: 'A', date: '20/07/2018', amount: -20, currency: 'USD'),
      t(account: 'A', category: 'A', date: '19/07/2018', amount: -20, currency: 'BBD'),
      t(account: 'B', category: 'B', date: '21/07/2018', amount: -75, currency: 'EUR'),
      t(account: 'C', category: 'A', date: '15/07/2018', amount: -5, currency: 'CUP'),
      t(account: 'C', category: 'A', date: '16/07/2018', amount: -50, currency: 'USD'),
      t(account: 'D', category: 'C', date: '17/07/2018', amount: -5, currency: 'BBD'),
      t(account: 'D', category: 'C', date: '14/07/2018', amount: -50, currency: 'USD')
    ]
  end
  let(:options) { {} }

  describe '#currencies' do
    subject { content.currencies }

    let(:transactions) do
      super() + [
        t(account: 'E', category: 'C', date: '14/07/2018', amount: -50, currency: 'AED'),
        t(account: 'E', category: 'C', date: '14/07/2018', amount: 50, currency: 'AED')
      ]
    end

    it { is_expected.to eq %w[USD CUP BBD EUR] }
  end

  describe '#accounts_currency' do
    subject { content.accounts_currency }

    it { is_expected.to eq('A' => 'BBD', 'B' => 'EUR', 'C' => 'CUP', 'D' => 'USD') }
  end

  describe '#accounts' do
    subject { content.accounts }

    let(:transactions) do
      super() + [
        t(account: 'E', category: 'C', date: '14/07/2018', amount: -50, currency: 'AED'),
        t(account: 'E', category: 'C', date: '14/07/2018', amount: +50, currency: 'AED')
      ]
    end

    let(:result) do
      {
        'A' => Money.new(-3000, 'USD'),
        'B' => Money.new(-7500, 'EUR'),
        'C' => Money.new(-128_000, 'CUP'),
        'D' => Money.new(-10_500, 'BBD')
      }
    end

    it { is_expected.to eq result }

    context 'when options[:all] is true' do
      let(:options) { {all: true} }

      let(:result) { super().merge('E' => Money.new(0, 'AED')) }

      it { is_expected.to eq result }
    end

    context 'when options[:date] is provided' do
      let(:options) { {date: Date.new(2018, 07, 15)} }

      let(:result) { {'C' => Money.new(-500, 'CUP'), 'D' => Money.new(-5000, 'USD')} }

      it { is_expected.to eq result }
    end
  end

  describe '#current' do
    subject { content.current }

    it { is_expected.to eq Money.new(-21_973, 'USD') }
  end

  describe '#trips' do
    subject { content.trips.map(&:list) }

    let(:transactions) do
      [
        t(account: 'A', category: 'A', date: '20/06/2018', amount: -20, currency: 'BBD', travel: 'Travel A'),
        t(account: 'A', category: 'A', date: '14/07/2018', amount: -20, currency: 'USD', travel: 'Travel A'),
        t(account: 'B', category: 'B', date: '15/07/2018', amount: -50, currency: 'USD', travel: 'Travel B'),
        t(account: 'B', category: 'B', date: '16/07/2018', amount: -50, currency: 'USD', travel: 'Travel B'),
        t(account: 'B', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD', travel: 'Travel B')
      ]
    end

    let(:result) do
      [
        Ledger::Trip.new('Travel A', transactions.slice(0, 2), transactions.slice(0, 4)),
        Ledger::Trip.new('Travel B', transactions.slice(2, 2), transactions.slice(0, 4))
      ].map(&:list)
    end

    it { is_expected.to eq result }

    context 'when a trip is defined' do
      let(:options) { {trip: 'Travel A'} }

      let(:result) { [Ledger::Trip.new('Travel A', transactions.slice(0, 2), transactions.slice(0, 4)).list] }

      it { is_expected.to eq result }
    end

    context 'when global is set to true' do
      let(:options) { {global: true, currency: 'USD'} }

      let(:exchanged_transaction) do
        [t(account: 'A', category: 'A', date: '20/06/2018', amount: -10, currency: 'USD', travel: 'Travel A')]
      end

      let(:result) do
        [
          Ledger::GlobalTrip.new(
            'Global', exchanged_transaction + transactions.slice(1, 3), exchanged_transaction + transactions.slice(1, 3)
          ).list
        ]
      end

      it { is_expected.to eq result }

      context 'when a trip is defined' do
        let(:options) { super().merge(trip: 'Travel A') }

        let(:result) do
          [
            Ledger::Trip.new(
              'Travel A', exchanged_transaction + transactions.slice(1, 1), exchanged_transaction + transactions.slice(1, 3)
            ).list
          ]
        end

        it { is_expected.to eq result }
      end

      context 'within a period' do
        let(:options) do
          super().merge(from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2018, month: 6)
        end

        let(:result) do
          [Ledger::GlobalTrip.new('Global', transactions.slice(1, 2), transactions.slice(1, 2)).list]
        end

        it { is_expected.to eq result }

        context 'without from param' do
          before { options.delete(:from) }

          let(:result) do
            [
              Ledger::GlobalTrip.new(
                'Global',
                exchanged_transaction + transactions.slice(1, 2),
                exchanged_transaction + transactions.slice(1, 2)
              ).list
            ]
          end

          it { is_expected.to eq result }
        end

        context 'without till param' do
          before { options.delete(:till) }

          let(:result) do
            [Ledger::GlobalTrip.new('Global', transactions.slice(1, 3), transactions.slice(1, 3)).list]
          end

          it { is_expected.to eq result }
        end

        context 'without till and from param' do
          before do
            options.delete(:till)
            options.delete(:from)
          end

          let(:result) do
            [Ledger::GlobalTrip.new('Global', exchanged_transaction, exchanged_transaction).list]
          end

          it { is_expected.to eq result }
        end

        context 'without till and from and year param' do
          before do
            options.delete(:till)
            options.delete(:from)
            options.delete(:year)
          end

          let(:result) do
            [
              Ledger::GlobalTrip.new(
                'Global',
                exchanged_transaction + transactions.slice(1, 3),
                exchanged_transaction + transactions.slice(1, 3)
              ).list
            ]
          end

          it { is_expected.to eq result }
        end

        context 'without till and from and month param' do
          before do
            options.delete(:till)
            options.delete(:from)
            options.delete(:month)
          end

          let(:result) do
            [
              Ledger::GlobalTrip.new(
                'Global',
                exchanged_transaction + transactions.slice(1, 3),
                exchanged_transaction + transactions.slice(1, 3)
              ).list
            ]
          end

          it { is_expected.to eq result }
        end
      end
    end
  end

  describe '#comparisons' do
    subject { content.comparisons.map(&:list) }

    let(:options) { {months: 1, currency: 'USD'} }

    let(:transactions) do
      [
        t(account: 'A', category: 'A', date: '20/05/2018', amount: -20, currency: 'BBD'),
        t(account: 'A', category: 'A', date: '14/07/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'B', date: '15/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'B', date: '16/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:periods) do
      [
        [Date.new(2018, 6, 1), Date.new(2018, 6, 30)],
        [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]
      ]
    end

    let(:result) do
      [
        Ledger::Comparison.new('A', transactions.slice(1, 1), periods, 'USD'),
        Ledger::Comparison.new('B', transactions.slice(2, 2), periods, 'USD'),
        Ledger::Comparison.new('Totals', transactions.slice(1, 3), periods, 'USD')
      ].map(&:list)
    end

    before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 22)) }

    it { is_expected.to eq result }

    context 'when months is set to 2' do
      let(:options) { {months: 2, currency: 'USD'} }

      let(:exchanged_transaction) do
        [t(account: 'A', category: 'A', date: '20/05/2018', amount: -10, currency: 'USD')]
      end

      let(:periods) { super().unshift([Date.new(2018, 5, 1), Date.new(2018, 5, 31)]) }

      let(:result) do
        [
          Ledger::Comparison.new('A', exchanged_transaction + transactions.slice(1, 1), periods, 'USD'),
          Ledger::Comparison.new('B', transactions.slice(2, 2), periods, 'USD'),
          Ledger::Comparison.new('Totals', exchanged_transaction + transactions.slice(1, 3), periods, 'USD')
        ].map(&:list)
      end

      it { is_expected.to eq result }
    end
  end

  describe '#reports' do
    subject { content.reports.map(&:list) }

    let(:transactions) do
      [
        t(account: 'A', category: 'A', date: '20/06/2017', amount: -20, currency: 'BBD'),
        t(account: 'A', category: 'A', date: '14/07/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'B', date: '15/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'B', date: '16/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:result) do
      [
        Ledger::Report.new('A', transactions.slice(0, 2)),
        Ledger::Report.new('B', transactions.slice(2, 2))
      ].map(&:list)
    end

    it { is_expected.to eq result }

    context 'when global is set to true' do
      let(:options) { {global: true, currency: 'USD'} }

      let(:exchanged_transaction) do
        [t(account: 'A', category: 'A', date: '20/06/2017', amount: -10, currency: 'USD')]
      end

      let(:result) do
        [Ledger::Report.new('Global', exchanged_transaction + transactions.slice(1, 3)).list]
      end

      it { is_expected.to eq result }

      context 'with excluded categories' do
        let(:options) { super().merge(categories: %w[b]) }

        let(:result) do
          [Ledger::Report.new('Global', exchanged_transaction + transactions.slice(1, 1)).list]
        end

        it { is_expected.to eq result }
      end

      context 'within a period' do
        let(:options) do
          super().merge(from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2017, month: 6)
        end

        let(:result) { [Ledger::Report.new('Global', transactions.slice(1, 2)).list] }

        it { is_expected.to eq result }

        context 'without from param' do
          before { options.delete(:from) }

          let(:result) { [Ledger::Report.new('Global', exchanged_transaction + transactions.slice(1, 2)).list] }

          it { is_expected.to eq result }
        end

        context 'without till param' do
          before { options.delete(:till) }

          let(:result) { [Ledger::Report.new('Global', transactions.slice(1, 3)).list] }

          it { is_expected.to eq result }
        end

        context 'without till and from param' do
          before do
            options.delete(:till)
            options.delete(:from)
          end

          let(:result) { [Ledger::Report.new('Global', exchanged_transaction).list] }

          it { is_expected.to eq result }
        end

        context 'without till and from and year param' do
          before do
            options.delete(:till)
            options.delete(:from)
            options.delete(:year)
          end

          let(:result) do
            [Ledger::Report.new('Global', exchanged_transaction + transactions.slice(1, 3)).list]
          end

          it { is_expected.to eq result }
        end

        context 'without till and from and month param' do
          before do
            options.delete(:till)
            options.delete(:from)
            options.delete(:month)
          end

          let(:result) do
            [Ledger::Report.new('Global', exchanged_transaction + transactions.slice(1, 3)).list]
          end

          it { is_expected.to eq result }
        end
      end
    end
  end

  describe '#studies' do
    subject { content.studies('C').map(&:list) }

    let(:transactions) do
      [
        t(account: 'A', category: 'C', date: '20/06/2017', amount: -20, currency: 'BBD'),
        t(account: 'A', category: 'C', date: '14/07/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'C', date: '15/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'C', date: '16/07/2018', amount: -10, currency: 'USD'),
        t(account: 'B', category: 'D', date: '18/07/2018', amount: -50, currency: 'USD'),
        t(account: 'A', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:result) do
      [
        Ledger::Study.new('A', transactions.slice(0, 2), transactions.slice(0, 5), transactions.slice(0, 5)),
        Ledger::Study.new('B', transactions.slice(2, 2), transactions.slice(0, 5), transactions.slice(0, 5))
      ].map(&:list)
    end

    it { is_expected.to eq result }

    context 'when global is set to true' do
      let(:options) { {global: true, currency: 'USD'} }

      let(:exchanged_transaction) do
        [t(account: 'A', category: 'C', date: '20/06/2017', amount: -10, currency: 'USD')]
      end

      let(:result) do
        [
          Ledger::Study.new(
            'Global',
            exchanged_transaction + transactions.slice(1, 3),
            exchanged_transaction + transactions.slice(1, 4),
            exchanged_transaction + transactions.slice(1, 4)
          )
        ].map(&:list)
      end

      it { is_expected.to eq result }

      context 'within a period' do
        let(:options) do
          super().merge(from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2017, month: 6)
        end

        let(:result) do
          [
            Ledger::Study.new(
              'Global',
              transactions.slice(1, 2),
              transactions.slice(1, 2),
              exchanged_transaction + transactions.slice(1, 3)
            )
          ].map(&:list)
        end

        it { is_expected.to eq result }

        context 'without from param' do
          before { options.delete(:from) }

          let(:result) do
            [
              Ledger::Study.new(
                'Global',
                exchanged_transaction + transactions.slice(1, 2),
                exchanged_transaction + transactions.slice(1, 2),
                exchanged_transaction + transactions.slice(1, 3)
              )
            ].map(&:list)
          end

          it { is_expected.to eq result }
        end

        context 'without till param' do
          before { options.delete(:till) }

          let(:result) do
            [
              Ledger::Study.new(
                'Global',
                transactions.slice(1, 3),
                transactions.slice(1, 4),
                transactions.slice(1, 4)
              )
            ].map(&:list)
          end

          it { is_expected.to eq result }
        end

        context 'without till and from param' do
          before do
            options.delete(:till)
            options.delete(:from)
          end

          let(:result) do
            [
              Ledger::Study.new(
                'Global',
                exchanged_transaction,
                exchanged_transaction,
                exchanged_transaction
              )
            ].map(&:list)
          end

          it { is_expected.to eq result }
        end

        context 'without till and from and year param' do
          before do
            options.delete(:till)
            options.delete(:from)
            options.delete(:year)
          end

          let(:result) do
            [
              Ledger::Study.new(
                'Global',
                exchanged_transaction + transactions.slice(1, 3),
                exchanged_transaction + transactions.slice(1, 4),
                exchanged_transaction + transactions.slice(1, 4)
              )
            ].map(&:list)
          end

          it { is_expected.to eq result }
        end

        context 'without till and from and month param' do
          before do
            options.delete(:till)
            options.delete(:from)
            options.delete(:month)
          end

          let(:result) do
            [
              Ledger::Study.new(
                'Global',
                exchanged_transaction + transactions.slice(1, 3),
                exchanged_transaction + transactions.slice(1, 4),
                exchanged_transaction + transactions.slice(1, 4)
              )
            ].map(&:list)
          end

          it { is_expected.to eq result }
        end
      end
    end
  end

  describe '#filtered_transactions' do
    subject { content.filtered_transactions }

    let(:transactions) do
      [
        t(account: 'A', category: 'C', date: '20/06/2017', amount: '-20.00', currency: 'BBD'),
        t(account: 'A', category: 'C', date: '14/07/2018', amount: '-20.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '15/07/2018', amount: '-50.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '16/07/2018', amount: '-10.00', currency: 'USD'),
        t(account: 'B', category: 'D', date: '18/07/2018', amount: '-50.00', currency: 'USD'),
        t(account: 'A', category: 'Exchange', date: '14/06/2018', amount: '-50.00', currency: 'USD')
      ]
    end

    it { is_expected.to eq transactions.slice(0, 5) }

    context 'with excluded categories' do
      let(:options) { {categories: %w[d]} }

      it { is_expected.to eq transactions.slice(0, 4) }
    end

    context 'with currency defined' do
      let(:options) { {currency: 'USD'} }

      it { is_expected.to eq transactions.slice(0, 5) }

      context 'with global option defined' do
        let(:options) { super().merge(global: true) }

        let(:exchanged_transaction) do
          [t(account: 'A', category: 'C', date: '20/06/2017', amount: '-10.00', currency: 'USD')]
        end

        it { is_expected.to eq exchanged_transaction + transactions.slice(1, 4) }
      end
    end

    context 'within a period' do
      let(:options) do
        {from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2017, month: 6}
      end

      it { is_expected.to eq transactions.slice(1, 2) }

      context 'without from param' do
        before { options.delete(:from) }

        it { is_expected.to eq transactions.slice(0, 3) }
      end

      context 'without till param' do
        before { options.delete(:till) }

        it { is_expected.to eq transactions.slice(1, 4) }
      end

      context 'without till and from param' do
        before do
          options.delete(:till)
          options.delete(:from)
        end

        it { is_expected.to eq transactions.slice(0, 1) }
      end

      context 'without till and from and year param' do
        before do
          options.delete(:till)
          options.delete(:from)
          options.delete(:year)
        end

        it { is_expected.to eq transactions.slice(0, 5) }
      end

      context 'without till and from and month param' do
        before do
          options.delete(:till)
          options.delete(:from)
          options.delete(:month)
        end

        it { is_expected.to eq transactions.slice(0, 5) }
      end
    end
  end

  describe '#excluded_transactions' do
    subject { content.excluded_transactions }

    let(:options) { {categories: %w[c]} }

    let(:transactions) do
      [
        t(account: 'A', category: 'C', date: '20/06/2017', amount: '-20.00', currency: 'BBD'),
        t(account: 'A', category: 'C', date: '14/07/2018', amount: '-20.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '15/07/2018', amount: '-50.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '16/07/2018', amount: '-10.00', currency: 'USD'),
        t(account: 'B', category: 'D', date: '18/07/2018', amount: '-50.00', currency: 'USD'),
        t(account: 'A', category: 'Exchange', date: '14/06/2018', amount: '-50.00', currency: 'USD')
      ]
    end

    it { is_expected.to eq transactions.slice(0, 4) }

    context 'without excluded categories' do
      let(:options) { {} }

      it { is_expected.to eq [] }
    end

    context 'with currency defined' do
      let(:options) { super().merge(currency: 'USD') }

      it { is_expected.to eq transactions.slice(0, 4) }

      context 'with global option defined' do
        let(:options) { super().merge(global: true) }

        let(:exchanged_transaction) do
          [t(account: 'A', category: 'C', date: '20/06/2017', amount: '-10.00', currency: 'USD')]
        end

        it { is_expected.to eq exchanged_transaction + transactions.slice(1, 3) }
      end
    end

    context 'within a period' do
      let(:options) do
        super().merge(from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2017, month: 6)
      end

      it { is_expected.to eq transactions.slice(1, 2) }

      context 'without from param' do
        before { options.delete(:from) }

        it { is_expected.to eq transactions.slice(0, 3) }
      end

      context 'without till param' do
        before { options.delete(:till) }

        it { is_expected.to eq transactions.slice(1, 3) }
      end

      context 'without till and from param' do
        before do
          options.delete(:till)
          options.delete(:from)
        end

        it { is_expected.to eq transactions.slice(0, 1) }
      end

      context 'without till and from and year param' do
        before do
          options.delete(:till)
          options.delete(:from)
          options.delete(:year)
        end

        it { is_expected.to eq transactions.slice(0, 4) }
      end

      context 'without till and from and month param' do
        before do
          options.delete(:till)
          options.delete(:from)
          options.delete(:month)
        end

        it { is_expected.to eq transactions.slice(0, 4) }
      end
    end
  end

  describe '#periods' do
    subject { content.periods }

    before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 22)) }

    context 'when number of months go to previous year' do
      let(:options) { {months: 8} }

      let(:periods) do
        [
          [Date.new(2017, 11, 1), Date.new(2017, 11, 30)],
          [Date.new(2017, 12, 1), Date.new(2017, 12, 31)],
          [Date.new(2018, 1, 1), Date.new(2018, 1, 31)],
          [Date.new(2018, 2, 1), Date.new(2018, 2, 28)],
          [Date.new(2018, 3, 1), Date.new(2018, 3, 31)],
          [Date.new(2018, 4, 1), Date.new(2018, 4, 30)],
          [Date.new(2018, 5, 1), Date.new(2018, 5, 31)],
          [Date.new(2018, 6, 1), Date.new(2018, 6, 30)],
          [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]
        ]
      end

      it { is_expected.to eq periods }
    end

    context 'when number of months do not go to previous year' do
      let(:options) { {months: 3} }

      let(:periods) do
        [
          [Date.new(2018, 4, 1), Date.new(2018, 4, 30)],
          [Date.new(2018, 5, 1), Date.new(2018, 5, 31)],
          [Date.new(2018, 6, 1), Date.new(2018, 6, 30)],
          [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]
        ]
      end

      it { is_expected.to eq periods }
    end
  end
end
