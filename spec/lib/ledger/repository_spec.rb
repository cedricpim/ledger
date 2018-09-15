RSpec.describe Ledger::Repository do
  subject(:repository) { described_class.new(options) }

  let(:options) { {} }

  let(:keys) { %w[account date category description venue amount currency processed travel] }
  let(:transactions) do
    [
      t(
        keys.map(&:to_sym).zip(
          ['Main', '23-06-2018', 'Category B', 'Initial Balance', nil, '+15.50', 'USD', 'yes', 'Travel D']
        ).to_h
      ),
      t(
        keys.map(&:to_sym).zip(
          ['Euro', '23-07-2018', 'Category A', 'Description C', 'Venue E', '-10.00', 'EUR', 'no', nil]
        ).to_h
      )
    ]
  end

  let(:path) { File.join('spec', 'fixtures', 'example.csv') }

  before do
    allow_any_instance_of(Ledger::Encryption)
      .to receive(:wrap)
      .and_yield(path)
  end

  describe '#load!' do
    subject { repository.load! }

    specify do
      expect { subject }.to change { repository.current_transactions }.from([]).to(transactions)
    end

    context 'when there is an error with Cipher' do
      before { expect(CSV).to receive(:foreach).and_raise(OpenSSL::Cipher::CipherError) }

      specify do
        expect { subject }.to raise_error(OpenSSL::Cipher::CipherError)
      end
    end

    context 'when there is an error loading a file' do
      let(:path) { File.join('spec', 'fixtures', 'wrong-example.csv') }
      let(:message) { 'A problem reading line 3 has occurred' }

      specify do
        expect { subject }.to raise_error(described_class::IncorrectCSVFormatError, message)
      end
    end
  end

  describe '#book!' do
    subject { repository.book! }

    let(:transaction) { instance_double('Ledger::Transaction', to_ledger: 'to_ledger') }
    let(:builder) { instance_double('Ledger::TransactionBuilder', build!: transaction) }
    let(:file) { instance_double('File') }

    specify do
      expect(Ledger::TransactionBuilder).to receive(:new).with(repository).and_return(builder)
      expect(File).to receive(:open).with(path, 'a').and_yield(file)
      expect(file).to receive(:write).with("to_ledger\n")
      expect(File).to receive(:read).with(path).and_return("something\n\nother\nanother\n\n")
      expect(File).to receive(:write).with(path, "something\nother\nanother\n")

      subject
    end
  end

  describe '#create!' do
    subject { repository.create! }

    let(:config) { File.join(ENV['HOME'], 'ledger-config-file.yml') }

    before { expect_any_instance_of(Ledger::Config).to receive(:ledger).and_return(config) }

    context 'when file exists' do
      before { allow(File).to receive(:exist?).with(config).and_return(true) }

      specify do
        expect(CSV).not_to receive(:open)
        subject
      end
    end

    context 'when file does not exist' do
      before { allow(File).to receive(:exist?).with(config).and_return(false) }

      let(:csv) { instance_double('CSV') }

      specify do
        expect(CSV).to receive(:open).with(config, 'wb').and_yield(csv)
        expect(csv).to receive(:<<).with(keys.map(&:capitalize).map(&:to_sym))
        expect_any_instance_of(Ledger::Encryption).to receive(:encrypt!)

        subject
      end
    end
  end

  describe '#edit!' do
    subject { repository.edit! }

    let(:editor) { 'vim' }
    let(:path) { instance_double('File', path: super()) }

    before { ENV['EDITOR'] = editor }

    specify do
      expect_any_instance_of(Kernel).to receive(:system).with([editor, path.path].join(' '))

      subject
    end

    context 'when a line is specified' do
      let(:options) { {line: 10} }

      specify do
        expect_any_instance_of(Kernel).to receive(:system).with([editor, "#{path.path}:10"].join(' '))

        subject
      end
    end
  end

  describe '#show' do
    subject { repository.show }

    let(:options) { {output: '/dev/stdout'} }

    specify do
      expect_any_instance_of(Kernel).to receive(:system).with("echo '#{transactions.map(&:to_ledger).join}' > /dev/stdout")

      subject
    end

    context 'when a date is defined' do
      let(:options) { super().merge(from: Date.new(2018, 6, 28), till: Date.new(2018, 9, 28)) }

      specify do
        expect_any_instance_of(Kernel).to receive(:system).with("echo '#{transactions[1].to_ledger}' > /dev/stdout")

        subject
      end
    end

    context 'when a currency is defined' do
      let(:options) { super().merge(currency: 'BBD') }

      let(:result) { transactions.map { |t| t.exchange_to(options[:currency]).to_ledger }.join }

      specify do
        expect_any_instance_of(Kernel).to receive(:system).with("echo '#{result}' > /dev/stdout")

        subject
      end
    end
  end

  (described_class::CONTENT_METHODS - %i[analysis]).each do |method|
    describe "##{method}" do
      subject { repository.public_send(method) }

      before { allow(repository).to receive(:load!) }

      specify do
        expect_any_instance_of(Ledger::Content).to receive(method)

        subject
      end
    end
  end

  describe '#analysis' do
    subject { repository.analysis('A') }

    before { allow(repository).to receive(:load!) }

    specify do
      expect_any_instance_of(Ledger::Content).to receive(:analysis).with('A')

      subject
    end
  end

  describe '#content' do
    let(:method) { (described_class::CONTENT_METHODS - %i[analysis]).sample }

    it 'calls #load! only once independently of the number of calls' do
      expect(repository).to receive(:load!)
      expect_any_instance_of(Ledger::Content).to receive(method).twice

      repository.public_send(method)
      repository.public_send(method)
    end
  end
end
