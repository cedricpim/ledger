RSpec.describe Ledger::Actions::Create do
  subject(:action) { described_class.new(options) }

  let(:options) { {} }

  describe '#call', :streaming do
    context 'when both files exist' do
      let(:ledger_content) { [build(:transaction)] }
      let(:networth_content) { [build(:networth)] }

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
          .to change { ledger.tap(&:rewind).read }.to(RSpecHelper.headers(Ledger::Transaction) + "\n")
          .and change { networth.tap(&:rewind).read }.to(RSpecHelper.headers(Ledger::Networth) + "\n")
      end
    end

    context 'when one file exists and the other does not' do
      let(:ledger_content) { [build(:transaction)] }

      it 'creates missing file' do
        expect do
          expect do
            action.call
          end.not_to change { ledger.tap(&:rewind).read }
        end.to change { networth.tap(&:rewind).read }.to(RSpecHelper.headers(Ledger::Networth) + "\n")
      end
    end
  end
end
