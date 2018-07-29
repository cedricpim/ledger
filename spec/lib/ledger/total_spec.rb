RSpec.describe Ledger::Total do
  subject(:totals) { described_class.new(repository) }

  let(:options) { {} }
  let(:repository) { Ledger::Repository.new(options) }

  before do
    allow(repository).to receive(:current_transactions).and_return(transactions)
    allow(repository).to receive(:load!)
  end

  describe '#for' do
    subject { totals.for(method: method, currency: currency) }

    let(:options) { {categories: %w[E]} }
    let(:transactions) do
      [
        t(account: 'A', category: 'Z', date: '20/07/2018', amount: 400, currency: 'BBD'),
        t(account: 'A', category: 'Y', date: '19/06/2018', amount: 200, currency: 'BBD'),
        t(account: 'A', category: 'E', date: '15/06/2018', amount: 100, currency: 'BBD'),
        t(account: 'B', category: 'X', date: '18/05/2018', amount: -20, currency: 'USD'),
        t(account: 'B', category: 'W', date: '17/04/2018', amount: -65, currency: 'USD'),
        t(account: 'C', category: 'V', date: '14/03/2018', amount: -30, currency: 'BBD'),
        t(account: 'D', category: 'U', date: '15/02/2018', amount: -10, currency: 'USD'),
        t(account: 'D', category: 'E', date: '15/02/2018', amount: -10, currency: 'USD')
      ]
    end

    context 'when method is :income' do
      let(:method) { :income }

      context 'when there are no transactions' do
        let(:currency) { :USD }
        let(:transactions) { [] }

        it { is_expected.to eq ['0.00$', width: 11, align: 'center', color: :black] }
      end

      context 'when currency is USD' do
        let(:currency) { :USD }

        it { is_expected.to eq ['290.00$', width: 11, align: 'center', color: :green] }
      end

      context 'when currency is BBD' do
        let(:currency) { :BBD }

        it { is_expected.to eq ['580.00$', width: 11, align: 'center', color: :green] }
      end

      context 'when currency is EUR' do
        let(:currency) { :EUR }

        it { is_expected.to eq ['249.92€', width: 11, align: 'center', color: :green] }
      end
    end

    context 'when method is :expense' do
      let(:method) { :expense }

      context 'when there are no transactions' do
        let(:currency) { :USD }
        let(:transactions) { [] }

        it { is_expected.to eq ['0.00$', width: 11, align: 'center', color: :black] }
      end

      context 'when currency is USD' do
        let(:currency) { :USD }

        it { is_expected.to eq ['60.00$', width: 11, align: 'center', color: :red] }
      end

      context 'when currency is BBD' do
        let(:currency) { :BBD }

        it { is_expected.to eq ['120.00$', width: 11, align: 'center', color: :red] }
      end

      context 'when currency is EUR' do
        let(:currency) { :EUR }

        it { is_expected.to eq ['51.71€', width: 11, align: 'center', color: :red] }
      end
    end
  end

  describe '#period_percentage' do
    subject { totals.period_percentage }

    context 'when expense / income is NaN' do
      let(:transactions) { [] }

      it { is_expected.to eq ['0.0%', width: 8, align: 'right', color: :black] }
    end

    context 'when there is only expense' do
      let(:transactions) do
        [t(account: 'A', category: 'Z', date: '20/07/2018', amount: -400, currency: 'USD')]
      end

      it { is_expected.to eq ['100.0%', width: 8, align: 'right', color: :red] }
    end

    context 'when there is only income' do
      let(:transactions) do
        [t(account: 'A', category: 'Z', date: '20/07/2018', amount: 400, currency: 'USD')]
      end

      it { is_expected.to eq ['100.0%', width: 8, align: 'right', color: :green] }
    end

    context 'when there is more income than expense' do
      context 'when there is more than two times' do
        let(:transactions) do
          [
            t(account: 'A', category: 'Z', date: '20/05/2018', amount: 120, currency: 'BBD'),
            t(account: 'A', category: 'Z', date: '20/03/2018', amount: 120, currency: 'USD'),
            t(account: 'A', category: 'Y', date: '20/02/2018', amount: -60, currency: 'USD')
          ]
        end

        it { is_expected.to eq ['66.67%', width: 8, align: 'right', color: :green] }
      end

      context 'when there is less than two times' do
        let(:transactions) do
          [
            t(account: 'A', category: 'Z', date: '20/05/2018', amount: 120, currency: 'BBD'),
            t(account: 'A', category: 'Z', date: '20/03/2018', amount: 20, currency: 'USD'),
            t(account: 'A', category: 'Y', date: '20/02/2018', amount: -60, currency: 'USD')
          ]
        end

        it { is_expected.to eq ['25.0%', width: 8, align: 'right', color: :green] }
      end
    end

    context 'when there is more expense than income' do
      context 'when there is more than two times' do
        let(:transactions) do
          [
            t(account: 'A', category: 'Z', date: '20/05/2018', amount: 200, currency: 'BBD'),
            t(account: 'A', category: 'Y', date: '20/03/2018', amount: -100, currency: 'USD'),
            t(account: 'A', category: 'Y', date: '20/02/2018', amount: -150, currency: 'USD')
          ]
        end

        it { is_expected.to eq ['250.0%', width: 8, align: 'right', color: :red] }
      end

      context 'when there is less than two times' do
        let(:transactions) do
          [
            t(account: 'A', category: 'Z', date: '20/05/2018', amount: 200, currency: 'BBD'),
            t(account: 'A', category: 'Y', date: '20/03/2018', amount: -100, currency: 'USD'),
            t(account: 'A', category: 'Y', date: '20/02/2018', amount: -75, currency: 'USD')
          ]
        end

        it { is_expected.to eq ['175.0%', width: 8, align: 'right', color: :red] }
      end
    end
  end

  describe '#total_percentage' do
    subject { totals.total_percentage }

    let(:options) { {from: Date.new(2018, 1, 1)} }

    context 'when expense / income is NaN' do
      let(:transactions) { [] }

      it { is_expected.to eq ['0.0%', width: 4, align: 'right', color: :black] }
    end

    context 'when there is only expense' do
      let(:transactions) do
        [t(account: 'A', category: 'Z', date: '20/07/2018', amount: -400, currency: 'USD')]
      end

      it { is_expected.to eq ['100.0%', width: 4, align: 'right', color: :red] }
    end

    context 'when there is only income' do
      let(:transactions) do
        [t(account: 'A', category: 'Z', date: '20/07/2018', amount: 400, currency: 'USD')]
      end

      it { is_expected.to eq ['100.0%', width: 4, align: 'right', color: :green] }
    end

    context 'when there is more income than expense' do
      let(:transactions) do
        [
          t(account: 'A', category: 'Z', date: '20/07/2018', amount: 300, currency: 'USD'),
          t(account: 'A', category: 'Z', date: '20/05/2018', amount: 300, currency: 'BBD'),
          t(account: 'A', category: 'Y', date: '20/03/2018', amount: -75, currency: 'USD'),
          t(account: 'A', category: 'Y', date: '20/02/2018', amount: -75, currency: 'USD')
        ] + other_transactions
      end

      context 'current is positive' do
        context 'when the current is less than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: 100, currency: 'USD')]
          end

          it { is_expected.to eq ['300.0%', width: 4, align: 'right', color: :green] }
        end

        context 'when the current is more than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: 800, currency: 'USD')]
          end

          it { is_expected.to eq ['37.5%', width: 4, align: 'right', color: :green] }
        end
      end

      context 'current is negative' do
        context 'when the current is less than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: -50, currency: 'USD')]
          end

          it { is_expected.to eq ['600.0%', width: 4, align: 'right', color: :green] }
        end

        context 'when the current is more than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: -1000, currency: 'USD')]
          end

          it { is_expected.to eq ['30.0%', width: 4, align: 'right', color: :green] }
        end
      end
    end

    context 'when there is more expense than income' do
      let(:transactions) do
        [
          t(account: 'A', category: 'Z', date: '20/05/2018', amount: 200, currency: 'BBD'),
          t(account: 'A', category: 'Y', date: '20/03/2018', amount: -100, currency: 'USD'),
          t(account: 'A', category: 'Y', date: '20/02/2018', amount: -150, currency: 'USD')
        ] + other_transactions
      end

      context 'current is positive' do
        context 'when the current is less than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: 50, currency: 'USD')]
          end

          it { is_expected.to eq ['300.0%', width: 4, align: 'right', color: :red] }
        end

        context 'when the current is more than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: 1000, currency: 'USD')]
          end

          it { is_expected.to eq ['15.0%', width: 4, align: 'right', color: :red] }
        end
      end

      context 'current is negative' do
        context 'when the current is less than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: -50, currency: 'USD')]
          end

          it { is_expected.to eq ['300.0%', width: 4, align: 'right', color: :red] }
        end

        context 'when the current is more than net result' do
          let(:other_transactions) do
            [t(account: 'J', category: 'I', date: '20/07/2017', amount: -300, currency: 'USD')]
          end

          it { is_expected.to eq ['50.0%', width: 4, align: 'right', color: :red] }
        end
      end
    end
  end
end
