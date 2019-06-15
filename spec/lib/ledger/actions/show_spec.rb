RSpec.describe Ledger::Actions::Show do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    let(:output) { '/dev/stdout' }
    let(:options) { {output: output} }

    let(:entries) { build_list(:transaction, 2) }
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
  end
end
