RSpec.describe Ledger::Repository do
  subject(:repository) { described_class.new }

  describe '#add', :streaming do
    subject(:add) { repository.add(entry) }

    let(:entry) { build(:transaction) }
    let(:ledger_content) { [] }

    let(:result) { RSpecHelper.build_result(Ledger::Transaction, entry) }

    it 'writes the transaction to file' do
      expect { add }.to change { ledger.tap(&:rewind).read }.to(result)
    end

    context 'when the resource is :networth' do
      subject(:add) { repository.add(entry, resource: :networth) }

      let(:entry) { build(:networth) }
      let(:networth_content) { [] }

      let(:result) { RSpecHelper.build_result(Ledger::Networth, entry) }

      it 'writes the networth to file' do
        expect { add }.to change { networth.tap(&:rewind).read }.to(result)
      end
    end

    context 'when no entries are passed' do
      subject(:add) { repository.add(nil) }

      let(:ledger_content) { build_list(:transaction, 2) }

      it 'writes nothing to the file' do
        expect { add }.not_to change { ledger.tap(&:rewind).read }
      end

      context 'when there is a reset' do
        subject(:add) { repository.add(nil, reset: true) }

        let(:result) { RSpecHelper.build_result(Ledger::Transaction) }

        it 'sets a new file with headers' do
          expect { add }.to change { ledger.tap(&:rewind).read }.to(result)
        end
      end
    end

    context 'when reset is passed' do
      subject(:add) { repository.add(entry, reset: true) }

      let(:ledger_content) { build_list(:transaction, 2) }

      let(:result) { RSpecHelper.build_result(Ledger::Transaction, entry) }

      it 'resets the file and add the transaction' do
        expect { add }.to change { ledger.tap(&:rewind).read }.to(result)
      end
    end
  end

  describe '#load', :streaming do
    subject(:load) { repository.load(resource) }

    let(:resource) { :ledger }
    let(:ledger_content) { build_list(:transaction, 2) }

    it 'returns an iterator over the list of transactions' do
      expect(load).to be_instance_of(Enumerator)
      expect(load.to_a).to match_array(ledger_content)
    end

    context 'when the resource is :networth' do
      let(:resource) { :networth }
      let(:networth_content) { build_list(:networth, 2) }

      it 'returns an iterator over the list of networth entries' do
        expect(load).to be_instance_of(Enumerator)
        expect(load.to_a).to match_array(networth_content)
      end
    end

    context 'when there is an error with CSV being malformed' do
      before { ledger.write('²') }

      specify do
        expect { load.to_a }.to raise_error(OpenSSL::Cipher::CipherError)
      end
    end

    context 'when there is an error loading a file' do
      let(:ledger_content) { build_list(:transaction, 2) + [build(:transaction).to_file + ',one other field'] }

      let(:message) { "A problem reading line #{ledger_content.count + 1} has occurred" }

      specify do
        expect { load.to_a }.to raise_error(described_class::IncorrectCSVFormatError, message)
      end
    end
  end

  describe '#open' do
    subject(:open) { repository.open(resource, &block) }

    let(:block) { proc { } }
    let(:resource) { :ledger }
    let(:encryption) { instance_double('Ledger::Encryption', resource: resource) }

    before do
      expect(Ledger::Encryption).to receive(:new).with(CONFIG.public_send(resource)).and_return(encryption)
      expect(encryption).to receive(:wrap).and_yield(&block)
    end

    specify { open }

    context 'when the resource is :networth' do
      let(:resource) { :networth }

      specify { open }
    end
  end

  describe '#analyses' do
    subject { repository.analyses('A') }

    specify do
      expect_any_instance_of(Ledger::Content).to receive(:analyses).with('A')

      subject
    end
  end

  (described_class::CONTENT_METHODS - %i[analyses]).each do |method|
    describe "##{method}" do
      subject { repository.public_send(method) }

      specify do
        expect_any_instance_of(Ledger::Content).to receive(method)

        subject
      end
    end
  end

  describe '#content' do
    let(:method) { (described_class::CONTENT_METHODS - %i[analyses]).sample }

    it 'calls #load only once independently of the number of calls' do
      expect(repository).to receive(:load).and_return([])
      expect_any_instance_of(Ledger::Content).to receive(method).twice

      repository.public_send(method)
      repository.public_send(method)
    end
  end
end
