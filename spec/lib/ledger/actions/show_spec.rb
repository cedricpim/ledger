RSpec.describe Ledger::Actions::Show do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:output) { '/dev/stdout' }
    let(:options) { {output: output} }

    let(:entries) { build_list(:transaction, 2) + [build(:transaction, currency: 'EUR')] }
    let(:ledger_content) { entries }

    before do
      entries.each { |entry| expect(action).to receive(:system).with("echo \"#{entry.to_file}\" >> #{output}") }
    end

    it 'shows each transaction' do
      action.call
    end

    context 'when a different output is defined' do
      let(:output) { '/tmp/ledger.log' }

      it 'appends each transaction into the output' do
        action.call
      end
    end

    context 'for networth resource' do
      let(:options) { super().merge(networth: true) }

      let(:entries) { build_list(:networth, 2) }
      let(:networth_content) { entries }

      it 'shows each transaction' do
        action.call
      end
    end

    context 'with some filters applied' do
      let(:options) { super().merge(from: Date.today - 2, till: Date.today + 2, categories: ['X']) }
      let(:filtered_entries) do
        [
          build(:transaction, date: (Date.today - 10).to_s),
          build(:transaction, date: (Date.today + 10).to_s),
          build(:transaction, category: 'x')
        ]
      end

      let(:ledger_content) { entries + filtered_entries }

      it 'shows only transactions that match filters' do
        action.call
      end
    end

    context 'with currency available' do
      let(:options) { super().merge(currency: 'USD') }

      let(:entries) { build_list(:transaction, 2) }
      let(:attributes) { attributes_for(:transaction, amount: '+10.00', currency: 'EUR') }
      let(:ledger_content) { entries + [build(:transaction, attributes)] }

      let(:exchanged_entry) { build(:transaction, attributes.merge(amount: '+11.60', currency: 'USD')) }

      before { expect(action).to receive(:system).with("echo \"#{exchanged_entry.to_file}\" >> #{output}") }

      it 'shows each transaction, exchanged' do
        action.call
      end
    end
  end
end
