RSpec.describe Ledger::Action::Create do
  subject(:action) { described_class.new }

  describe '#call', :streaming do
    def headers(klass)
      klass.members.map(&:capitalize).join(',')
    end

    context 'when both files exist' do
      let(:ledger_content) { 'something' }
      let(:networth_content) { 'something else' }

      it 'does nothing' do
        expect do
          expect do
            action.call
          end.not_to change { networth.tap(&:rewind).read }
        end.not_to change { networth.tap(&:rewind).read }
      end
    end

    context 'when no file exists yet' do
      it 'creates both files with proper headers' do
        expect { action.call }
          .to change { ledger.tap(&:rewind).read }.to(headers(Ledger::Transaction) + "\n")
          .and change { networth.tap(&:rewind).read }.to(headers(Ledger::Networth) + "\n")
      end
    end

    context 'when one file exists and the other does not' do
      let(:ledger_content) { 'something' }

      it 'creates missing file' do
        expect do
          expect do
            action.call
          end.not_to change { ledger.tap(&:rewind).read }
        end.to change { networth.tap(&:rewind).read }.to(headers(Ledger::Networth) + "\n")
      end
    end
  end
end
