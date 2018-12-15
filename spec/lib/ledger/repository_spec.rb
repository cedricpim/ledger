RSpec.describe Ledger::Repository do
  subject(:repository) { described_class.new(options) }

  let(:options) { {} }
  let(:keys) { %w[account date category description venue amount currency travel] }
  let(:path) { File.join('spec', 'fixtures', 'example.csv') }

  before do
    allow(File).to receive(:new).and_return(path)

    allow_any_instance_of(Ledger::Encryption)
      .to receive(:wrap)
      .and_yield(path)
  end

  describe '#book!' do
    subject { repository.book! }

    let(:transaction) { instance_double('Ledger::Transaction', to_file: 'to_file') }
    let(:builder) { instance_double('Ledger::TransactionBuilder', build!: transaction) }
    let(:file) { instance_double('File') }

    specify do
      expect(Ledger::TransactionBuilder).to receive(:new).with(repository).and_return(builder)
      expect(File).to receive(:open).with(path, 'a').and_yield(file)
      expect(file).to receive(:write).with("to_file\n")
      expect(File).to receive(:read).with(path).and_return("something\n\nother\nanother\n\n")
      expect(File).to receive(:write).with(path, "something\nother\nanother\n")

      subject
    end
  end

  describe '#create!' do
    subject { repository.create! }

    let(:filepath) { File.join(ENV['HOME'], 'file.csv') }
    let(:method) { :ledger }

    before { allow_any_instance_of(Ledger::Config).to receive(method).and_return(filepath) }

    context 'when file exists' do
      before { allow(File).to receive(:exist?).with(filepath).and_return(true) }

      specify do
        expect(CSV).not_to receive(:open)
        subject
      end
    end

    context 'when file does not exist' do
      let(:csv) { instance_double('CSV') }
      let(:encryption) { instance_double('Ledger::Encryption', encrypt!: nil) }

      before do
        allow(File).to receive(:exist?).with(filepath).and_return(false)
      end

      specify do
        expect(CSV).to receive(:open).with(filepath, 'wb').and_yield(csv)
        expect(csv).to receive(:<<).with(keys.map(&:capitalize).map(&:to_sym))
        expect(Ledger::Encryption).to receive(:new).with(filepath).and_return(encryption)

        subject
      end

      context 'when networth file does not exist' do
        let(:method) { :networth }
        let(:options) { {networth: true} }
        let(:keys) { %w[date investment amount currency] }

        specify do
          expect(CSV).to receive(:open).with(filepath, 'wb').and_yield(csv)
          expect(csv).to receive(:<<).with(keys.map(&:capitalize).map(&:to_sym))
          expect(Ledger::Encryption).to receive(:new).with(filepath).and_return(encryption)

          subject
        end
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

    let(:transactions) do
      [
        t(
          keys.map(&:to_sym).zip(
            ['Main', '2018-06-23', 'Category B', 'Initial Balance', nil, '+15.50', 'USD', 'Travel D']
          ).to_h
        ),
        t(
          keys.map(&:to_sym).zip(
            ['Euro', '2018-07-23', 'Category A', 'Description C', 'Venue E', '-10.00', 'EUR', nil]
          ).to_h
        )
      ]
    end

    specify do
      expect_any_instance_of(Kernel)
        .to receive(:system)
        .with("echo \"#{transactions.map(&:to_file).join}\" > /dev/stdout")

      subject
    end

    context 'when a date is defined' do
      let(:options) { super().merge(from: Date.new(2018, 6, 28), till: Date.new(2018, 9, 28)) }

      specify do
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{transactions[1].to_file}\" > /dev/stdout")

        subject
      end
    end

    context 'when a currency is defined' do
      let(:options) { super().merge(currency: 'BBD') }

      let(:result) { transactions.map { |t| t.exchange_to(options[:currency]).to_file }.join }

      specify do
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{result}\" > /dev/stdout")

        subject
      end
    end

    context 'when networth is defined' do
      let(:options) { super().merge(networth: true) }
      let(:path) { File.join('spec', 'fixtures', 'example-networth.csv') }
      let(:result) do
        [
          Ledger::Networth.new(date: '2018-06-23', investment: '+5.00', amount: '+15.50', currency: 'USD'),
          Ledger::Networth.new(date: '2018-07-23', investment: '+4.50', amount: '-10.00', currency: 'USD')
        ].map(&:to_file).join
      end

      specify do
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{result}\" > /dev/stdout")

        subject
      end
    end
  end

  describe '#analyses' do
    subject { repository.analyses('A') }

    before { allow(repository).to receive(:load!).and_yield }

    specify do
      expect_any_instance_of(Ledger::Content).to receive(:analyses).with('A')

      subject
    end
  end

  describe '#networth!' do
    subject { repository.networth! }

    let(:networth) { instance_double('Ledger::Networth', to_file: 'to_file') }
    let(:file) { instance_double('File') }

    specify do
      expect_any_instance_of(Ledger::Content).to receive(:current_networth).and_return(networth)
      expect(CSV).to receive(:foreach)
      expect(File).to receive(:open).with(path, 'a').and_yield(file)
      expect(file).to receive(:write).with("to_file\n")
      expect(File).to receive(:read).with(path).and_return("something\n\nother\nanother\n\n")
      expect(File).to receive(:write).with(path, "something\nother\nanother\n")

      subject
    end
  end

  (described_class::CONTENT_METHODS - %i[analyses]).each do |method|
    describe "##{method}" do
      subject { repository.public_send(method) }

      before { allow(repository).to receive(:load!).and_yield }

      specify do
        expect_any_instance_of(Ledger::Content).to receive(method)

        subject
      end
    end
  end

  described_class::NETWORTH_CONTENT_METHODS.each do |method|
    describe "##{method}" do
      subject { repository.public_send(method) }

      before { allow(repository).to receive(:load!).and_yield }

      specify do
        expect_any_instance_of(Ledger::NetworthContent).to receive(method)

        subject
      end
    end
  end

  describe '#content' do
    let(:method) { (described_class::CONTENT_METHODS - %i[analyses]).sample }

    it 'calls #load! only once independently of the number of calls' do
      expect(repository).to receive(:load!).and_yield
      expect_any_instance_of(Ledger::Content).to receive(method).twice

      repository.public_send(method)
      repository.public_send(method)
    end

    context 'when there is an error with Cipher' do
      before { expect(CSV).to receive(:foreach).and_raise(OpenSSL::Cipher::CipherError) }

      specify do
        expect { repository.public_send(method) }.to raise_error(OpenSSL::Cipher::CipherError)
      end
    end

    context 'when there is an error loading a file' do
      let(:path) { File.join('spec', 'fixtures', 'wrong-example.csv') }
      let(:message) { 'A problem reading line 3 has occurred' }

      specify do
        expect { repository.public_send(method) }.to raise_error(described_class::IncorrectCSVFormatError, message)
      end
    end
  end
end
