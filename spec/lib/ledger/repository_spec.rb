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
      before do
        ledger.seek(0, IO::SEEK_END)
        ledger.write('"')
        ledger.rewind
      end

      specify do
        expect { load.to_a }.to raise_error(OpenSSL::Cipher::CipherError)
      end
    end

    context 'when a line is not valid' do
      let(:line_number) { ledger_content.count + 1 }
      let(:message) { "There was an invalid line while parsing the CSV (Line #{line_number})" }

      context 'when there is an extra field' do
        let(:ledger_content) { build_list(:transaction, 2) + [build(:transaction).to_file + ',one other field'] }

        specify do
          expect { load.to_a }.to raise_error(described_class::LineError, message)
        end
      end

      context 'when the date is invalid' do
        let(:ledger_content) { build_list(:transaction, 2) + [build(:transaction, date: 'invalid_date').to_file] }

        specify do
          expect { load.to_a }.to raise_error(described_class::LineError, message)
        end
      end

      context 'when the money value is invalid' do
        let(:ledger_content) { build_list(:transaction, 2) + [build(:transaction, amount: '-').to_file] }

        specify do
          expect { load.to_a }.to raise_error(described_class::LineError, message)
        end
      end

      context 'when the investment value is invalid' do
        let(:resource) { :networth }
        let(:networth_content) { build_list(:networth, 2) + [build(:networth, investment: 'aaa').to_file] }
        let(:line_number) { networth_content.count + 1 }

        specify do
          expect { load.to_a }.to raise_error(described_class::LineError, message)
        end
      end

      context 'when the invested value is missing' do
        let(:resource) { :networth }
        let(:networth_content) { build_list(:networth, 2) + [build(:networth, invested: nil).to_file] }
        let(:line_number) { networth_content.count + 1 }

        specify do
          expect { load.to_a }.to raise_error(described_class::LineError, message)
        end
      end

      context 'when the currency is invalid' do
        let(:ledger_content) { build_list(:transaction, 2) + [build(:transaction, currency: 'x').to_file] }

        specify do
          expect { load.to_a }.to raise_error(described_class::LineError, message)
        end
      end
    end
  end

  describe '#open' do
    subject(:open) { repository.open(resource, &block) }

    let(:block) { proc {} }
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
end
