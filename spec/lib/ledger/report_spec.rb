RSpec.describe Ledger::Report do
  subject(:report) { described_class.new(account, transactions) }

  let(:account) { 'Account' }

  let(:transactions_a) do
    Array.new(10) do
      t(account: account, category: 'AA', date: '20/07/2018', amount: -2, currency: 'USD')
    end
  end

  let(:transactions) do
    [
      t(account: account, category: 'BBB', date: '19/07/2018', amount: -30, currency: 'USD'),
      t(account: account, category: 'CCCC', date: '19/07/2018', amount: 5, currency: 'USD')
    ] + transactions_a
  end

  describe '#list' do
    subject { report.list }

    let(:result) { [['(1)   CCCC', '+5.00$', 100.0], ['(1)   BBB', '-30.00$', 60.0], ['(10)  AA', '-20.00$', 40.0]] }

    it { is_expected.to eq result }
  end
end
