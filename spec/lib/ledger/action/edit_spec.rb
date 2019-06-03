RSpec.describe Ledger::Action::Edit do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :stubbing do
    let(:editor) { 'vim' }

    before do
      ENV['EDITOR'] = editor
      allow(ledger).to receive(:path).and_return('ledger')
      allow(networth).to receive(:path).and_return('networth')
    end

    specify do
      expect(action).to receive(:system).with([editor, 'ledger'].join(' '))

      action.call
    end

    context 'when EDITOR is nil' do
      let(:editor) { nil }

      specify do
        expect(action).to receive(:puts).with('No editor defined ($EDITOR)')
        expect(action).not_to receive(:system)

        action.call
      end
    end

    context 'when networth is specified' do
      let(:options) { {networth: true} }

      specify do
        expect(action).to receive(:system).with([editor, 'networth'].join(' '))

        action.call
      end
    end

    context 'when a line is specified' do
      let(:options) { {line: 10} }

      specify do
        expect(action).to receive(:system).with([editor, 'ledger:10'].join(' '))

        action.call
      end
    end
  end
end
