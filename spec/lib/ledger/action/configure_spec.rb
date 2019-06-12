RSpec.describe Ledger::Action::Configure do
  subject(:action) { described_class.new }

  describe '#call' do
    context 'default configuration exists' do
      before { allow(File).to receive(:exist?).with(::Ledger::Config::DEFAULT_CONFIG).and_return(true) }

      specify do
        expect(File).not_to receive(:dirname)
        expect(FileUtils).not_to receive(:mkdir_p)
        expect(FileUtils).not_to receive(:cp)

        expect(action.call).to be_nil
      end
    end

    context 'default configuration does not exist' do
      before { allow(File).to receive(:exist?).with(::Ledger::Config::DEFAULT_CONFIG).and_return(false) }

      specify do
        expect(File).to receive(:dirname).with(::Ledger::Config::DEFAULT_CONFIG).and_return('dirname')
        expect(FileUtils).to receive(:mkdir_p).with('dirname')
        expect(FileUtils).to receive(:cp).with(::Ledger::Config::FALLBACK_CONFIG, ::Ledger::Config::DEFAULT_CONFIG)

        action.call
      end
    end
  end
end
