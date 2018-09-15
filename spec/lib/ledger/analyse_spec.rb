RSpec.describe Ledger::Analyse do
  subject(:report) { described_class.new(account, transactions, period_transactions, total_transactions) }

  let(:account) { 'Account' }

  let(:transactions_b) do
    Array.new(10) do
      t(account: account, category: 'A', description: 'B', date: '20/07/2018', amount: -2, currency: 'USD')
    end
  end

  let(:transactions) do
    [
      t(account: account, category: 'A', description: 'CC', date: '15/07/2018', amount: -30, currency: 'USD'),
      t(account: account, category: 'A', description: 'CCC', date: '19/07/2018', amount: -10, currency: 'USD')
    ] + transactions_b
  end

  let(:period_transactions) do
    [
      t(account: account, category: 'B', description: 'A', date: '11/07/2018', amount: -20, currency: 'USD'),
      t(account: account, category: 'C', description: 'AA', date: '09/07/2018', amount: -20, currency: 'USD')
    ] + transactions
  end

  let(:total_transactions) do
    [
      t(account: account, category: 'A', description: 'B', date: '19/05/2018', amount: -80, currency: 'USD'),
      t(account: account, category: 'D', description: 'CCC', date: '19/06/2018', amount: 500, currency: 'USD')
    ] + period_transactions
  end

  describe '#list' do
    subject { report.list }

    let(:result) do
      [
        ['(1)   CC', '-30.00$', 50.00, 30.00],
        ['(10)  B', '-20.00$', 33.33, 20.00],
        ['(1)   CCC', '-10.00$', 16.67, 10.00]
      ]
    end

    it { is_expected.to eq result }
  end

  describe '#total' do
    subject { report.total }

    let(:result) { ['(12)  A', '-60.00$', 60.00, 33.33] }

    it { is_expected.to eq result }
  end
end
