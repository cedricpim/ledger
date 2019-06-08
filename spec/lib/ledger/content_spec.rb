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

    it { is_expected.to match_array(%w[USD CUP BBD EUR]) }
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
      let(:options) { {date: Date.new(2018, 7, 15)} }

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

    let(:relevant) do
      [
        t(account: 'A', category: 'A', date: '20/06/2018', amount: -20, currency: 'BBD', travel: 'Travel A'),
        t(account: 'A', category: 'A', date: '14/07/2018', amount: -20, currency: 'USD', travel: 'Travel A'),
        t(account: 'B', category: 'B', date: '15/07/2018', amount: -50, currency: 'USD', travel: 'Travel B'),
        t(account: 'B', category: 'B', date: '16/07/2018', amount: -50, currency: 'USD', travel: 'Travel B'),
        t(account: 'Vacation', category: 'X', date: '18/07/2018', amount: -50, currency: 'USD', travel: 'Travel B'),
      ]
    end

    let(:transactions) do
      relevant + [t(account: 'B', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD', travel: 'Travel B')]
    end

    let(:result) do
      [
        Ledger::Trip.new('Travel A', relevant[0..1], relevant),
        Ledger::Trip.new('Travel B', relevant[2..-1], relevant)
      ].map(&:list)
    end

    it { is_expected.to eq result }

    context 'when a trip is defined' do
      let(:options) { {trip: 'Travel A'} }

      let(:result) { [super()[0]] }

      it { is_expected.to eq result }
    end

    context 'when global is set to true' do
      let(:options) { {global: true} }

      let(:result) { [Ledger::GlobalTrip.new('Global', relevant, relevant).list] }

      it { is_expected.to eq result }
    end

    context 'when a specific currency is defined' do
      let(:options) { {currency: 'USD'} }

      let(:exchanged_transaction) { [relevant[0].exchange_to(options[:currency])] }

      let(:result) do
        [
          Ledger::Trip.new('Travel A', exchanged_transaction + relevant[1..1], exchanged_transaction + relevant[1..-1]),
          Ledger::Trip.new('Travel B', relevant[2..-1], exchanged_transaction + relevant[1..-1])
        ].map(&:list)
      end

      it { is_expected.to eq result }
    end
  end

  describe '#comparisons' do
    subject { content.comparisons.map(&:list) }

    let(:options) { {months: 1} }

    let(:relevant) do
      [
        t(account: 'A', category: 'A', date: '20/05/2018', amount: -20, currency: 'BBD'),
        t(account: 'A', category: 'A', date: '14/07/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'B', date: '15/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'B', date: '16/07/2018', amount: -50, currency: 'USD'),
        t(account: 'Vacation', category: 'X', date: '18/07/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:transactions) do
      relevant + [t(account: 'B', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')]
    end

    let(:periods) do
      [
        [Date.new(2018, 6, 1), Date.new(2018, 6, 30)],
        [Date.new(2018, 7, 1), Date.new(2018, 7, 31)]
      ]
    end

    let(:result) do
      [
        Ledger::Comparison.new('A', relevant[1..1], periods, 'USD'),
        Ledger::Comparison.new('B', relevant[2..3], periods, 'USD'),
        Ledger::Comparison.new('X', relevant[4..4], periods, 'USD'),
        Ledger::Comparison.new('Totals', relevant[1..-1], periods, 'USD')
      ].map(&:list)
    end

    before { allow(Date).to receive(:today).and_return(Date.new(2018, 7, 22)) }

    it { is_expected.to eq result }

    context 'when months is set to 2' do
      let(:options) { {months: 2} }

      let(:periods) { super().unshift([Date.new(2018, 5, 1), Date.new(2018, 5, 31)]) }

      let(:result) do
        [
          Ledger::Comparison.new('A', relevant[0..1], periods, 'USD'),
          Ledger::Comparison.new('B', relevant[2..3], periods, 'USD'),
          Ledger::Comparison.new('X', relevant[4..4], periods, 'USD'),
          Ledger::Comparison.new('Totals', relevant[0..-1], periods, 'USD')
        ].map(&:list)
      end

      it { is_expected.to eq result }

      context 'when a specific currency is defined' do
        let(:options) { super().merge(currency: 'USD') }

        let(:exchanged_transaction) { [relevant[0].exchange_to(options[:currency])] }

        let(:result) do
          [
            Ledger::Comparison.new('A', exchanged_transaction + relevant[1..1], periods, 'USD'),
            Ledger::Comparison.new('B', relevant[2..3], periods, 'USD'),
            Ledger::Comparison.new('X', relevant[4..4], periods, 'USD'),
            Ledger::Comparison.new('Totals', exchanged_transaction + relevant[1..-1], periods, 'USD')
          ].map(&:list)
        end

        it { is_expected.to eq result }
      end
    end
  end

  describe '#reports' do
    subject { content.reports.map(&:list) }

    let(:relevant) do
      [
        t(account: 'A', category: 'A', date: '20/06/2017', amount: -20, currency: 'BBD'),
        t(account: 'A', category: 'A', date: '14/07/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'B', date: '15/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'B', date: '16/07/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:transactions) do
      relevant + [
        t(account: 'Vacation', category: 'X', date: '18/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:result) do
      [
        Ledger::Report.new('A', relevant[0..1]),
        Ledger::Report.new('B', relevant[2..3])
      ].map(&:list)
    end

    it { is_expected.to eq result }

    context 'when a specific currency is defined' do
      let(:options) { {currency: 'USD'} }

      let(:exchanged_transaction) { [relevant[0].exchange_to(options[:currency])] }

      let(:result) do
        [
          Ledger::Report.new('A', exchanged_transaction + relevant[1..1]),
          Ledger::Report.new('B', relevant[2..3])
        ].map(&:list)
      end

      it { is_expected.to eq result }
    end

    context 'when global is set to true' do
      let(:options) { {global: true} }

      let(:result) { [Ledger::Report.new('Global', relevant).list] }

      it { is_expected.to eq result }
    end

    context 'with excluded categories' do
      let(:options) { {categories: %w[b]} }

      let(:result) { [Ledger::Report.new('A', relevant[0..1])].map(&:list) }

      it { is_expected.to eq result }
    end

    context 'within a period' do
      let(:options) { {from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2017, month: 6} }

      let(:result) do
        [
          Ledger::Report.new('A', relevant[1..1]),
          Ledger::Report.new('B', relevant[2..2])
        ].map(&:list)
      end

      it { is_expected.to eq result }

      context 'without from param' do
        before { options.delete(:from) }

        let(:result) do
          [
            Ledger::Report.new('A', relevant[0..1]),
            Ledger::Report.new('B', relevant[2..2])
          ].map(&:list)
        end

        it { is_expected.to eq result }
      end

      context 'without till param' do
        before { options.delete(:till) }

        let(:result) do
          [
            Ledger::Report.new('A', relevant[1..1]),
            Ledger::Report.new('B', relevant[2..3])
          ].map(&:list)
        end

        it { is_expected.to eq result }
      end

      context 'without till and from param' do
        before do
          options.delete(:till)
          options.delete(:from)
        end

        let(:result) { [Ledger::Report.new('A', relevant[0..0])].map(&:list) }

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
            Ledger::Report.new('A', relevant[0..1]),
            Ledger::Report.new('B', relevant[2..3])
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
            Ledger::Report.new('A', relevant[0..1]),
            Ledger::Report.new('B', relevant[2..3])
          ].map(&:list)
        end

        it { is_expected.to eq result }
      end
    end
  end

  describe '#analyses' do
    subject { content.analyses('C').map(&:list) }

    let(:relevant) do
      [
        t(account: 'A', category: 'C', date: '20/06/2017', amount: -20, currency: 'BBD'),
        t(account: 'A', category: 'C', date: '14/07/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'C', date: '15/07/2018', amount: -50, currency: 'USD'),
        t(account: 'B', category: 'C', date: '16/07/2018', amount: -10, currency: 'USD'),
        t(account: 'B', category: 'D', date: '18/07/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:transactions) do
      relevant + [
        t(account: 'Vacation', category: 'C', date: '18/07/2018', amount: -50, currency: 'USD'),
        t(account: 'A', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    let(:result) do
      [
        Ledger::Analysis.new('A', relevant[0..1], relevant, relevant),
        Ledger::Analysis.new('B', relevant[2..3], relevant, relevant)
      ].map(&:list)
    end

    it { is_expected.to eq result }

    context 'when a specific currency is defined' do
      let(:options) { {currency: 'USD'} }

      let(:exchanged_transaction) { [relevant[0].exchange_to(options[:currency])] }

      let(:result) do
        total = exchanged_transaction + relevant[1..-1]
        [
          Ledger::Analysis.new('A', exchanged_transaction + relevant[1..1], total, total),
          Ledger::Analysis.new('B', relevant[2..3], total, total)
        ].map(&:list)
      end

      it { is_expected.to eq result }
    end

    context 'when global is set to true' do
      let(:options) { {global: true} }

      let(:result) do
        [Ledger::Analysis.new('Global', transactions[0..3], relevant, relevant)].map(&:list)
      end

      it { is_expected.to eq result }
    end

    context 'within a period' do
      let(:options) { {from: Date.new(2018, 7, 14), till: Date.new(2018, 7, 15), year: 2017, month: 6} }

      let(:result) do
        [
          Ledger::Analysis.new('A', relevant[1..1], relevant[1..2], relevant),
          Ledger::Analysis.new('B', relevant[2..2], relevant[1..2], relevant)
        ].map(&:list)
      end

      it { is_expected.to eq result }

      context 'without from param' do
        before { options.delete(:from) }

        let(:result) do
          [
            Ledger::Analysis.new('A', relevant[0..1], relevant[0..2], relevant),
            Ledger::Analysis.new('B', relevant[2..2], relevant[0..2], relevant)
          ].map(&:list)
        end

        it { is_expected.to eq result }
      end

      context 'without till param' do
        before { options.delete(:till) }

        let(:result) do
          [
            Ledger::Analysis.new('A', relevant[1..1], relevant[1..4], relevant),
            Ledger::Analysis.new('B', relevant[2..3], relevant[1..4], relevant)
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
            Ledger::Analysis.new('A', relevant[0..0], relevant[0..0], relevant)
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
            Ledger::Analysis.new('A', relevant[0..1], relevant, relevant),
            Ledger::Analysis.new('B', relevant[2..3], relevant, relevant)
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
            Ledger::Analysis.new('A', relevant[0..1], relevant, relevant),
            Ledger::Analysis.new('B', relevant[2..3], relevant, relevant)
          ].map(&:list)
        end

        it { is_expected.to eq result }
      end
    end
  end

  describe '#filtered_transactions' do
    subject { content.filtered_transactions }

    let(:relevant) do
      [
        t(account: 'A', category: 'C', date: '20/06/2017', amount: '-20.00', currency: 'BBD'),
        t(account: 'A', category: 'C', date: '14/07/2018', amount: '-20.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '15/07/2018', amount: '-50.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '16/07/2018', amount: '-10.00', currency: 'USD'),
        t(account: 'B', category: 'D', date: '18/07/2018', amount: '-50.00', currency: 'USD')
      ]
    end

    let(:transactions) do
      relevant + [
        t(account: 'Vacation', category: 'C', date: '18/07/2018', amount: -50, currency: 'USD'),
        t(account: 'A', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    it { is_expected.to eq relevant }

    context 'with excluded categories' do
      let(:options) { {categories: %w[d]} }

      it { is_expected.to eq relevant[0..3] }
    end

    context 'with currency defined' do
      let(:options) { {currency: 'USD'} }

      let(:exchanged_transaction) { [relevant[0].exchange_to(options[:currency])] }

      it { is_expected.to eq exchanged_transaction + relevant[1..4] }
    end
  end

  describe '#excluded_transactions' do
    subject { content.excluded_transactions }

    let(:options) { {categories: %w[c]} }

    let(:relevant) do
      [
        t(account: 'A', category: 'C', date: '20/06/2017', amount: '-20.00', currency: 'BBD'),
        t(account: 'A', category: 'C', date: '14/07/2018', amount: '-20.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '15/07/2018', amount: '-50.00', currency: 'USD'),
        t(account: 'B', category: 'C', date: '16/07/2018', amount: '-10.00', currency: 'USD'),
        t(account: 'B', category: 'D', date: '18/07/2018', amount: '-50.00', currency: 'USD')
      ]
    end

    let(:transactions) do
      relevant + [
        t(account: 'Vacation', category: 'C', date: '18/07/2018', amount: -50, currency: 'USD'),
        t(account: 'A', category: 'Exchange', date: '14/06/2018', amount: -50, currency: 'USD')
      ]
    end

    it { is_expected.to eq relevant[0..3] }

    context 'without excluded categories' do
      let(:options) { {} }

      it { is_expected.to eq [] }
    end

    context 'with currency defined' do
      let(:options) { super().merge(currency: 'USD') }

      let(:exchanged_transaction) { [relevant[0].exchange_to(options[:currency])] }

      it { is_expected.to eq exchanged_transaction + transactions[1..3] }
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
