RSpec.describe Ledger::Repository do
  subject(:repository) { described_class.new(options) }

  let(:options) { {} }
  let(:keys) { %w[account date category description venue amount currency travel] }
  let(:path) { File.join('spec', 'fixtures', 'example.csv') }
  let(:networth_path) { File.join('spec', 'fixtures', 'example-networth.csv') }
  let(:encryption) { instance_double('Ledger::Encryption') }
  let(:networth_encryption) { instance_double('Ledger::Encryption') }

  before do
    # allow(File).to receive(:new).and_return(path, networth_path)

    allow_any_instance_of(Ledger::Config).to receive(:ledger).and_return(path)
    allow_any_instance_of(Ledger::Config).to receive(:networth).and_return(networth_path)

    # allow(Ledger::Encryption).to receive(:new).with(path).and_return(encryption)
    # allow(encryption).to receive(:wrap).and_yield(path)

    # allow(Ledger::Encryption).to receive(:new).with(networth_path).and_return(networth_encryption)
    # allow(networth_encryption).to receive(:wrap).and_yield(networth_path)

    # allow(CSV).to receive(:open).with(path, Hash).and_call_original
    # allow(File).to receive(:open).with(path, String, Hash).and_call_original
    # allow(CSV).to receive(:open).with(networth_path, Hash).and_call_original
    # allow(File).to receive(:open).with(networth_path, String, Hash).and_call_original
  end

  describe '#add' do
    let(:transaction) { build(:transaction) }
    let(:file) { StringIO.new }

    before do
      allow(Ledger::Encryption).to receive(:new).with(CONFIG.ledger).and_return(encryption)
      allow(encryption).to receive(:wrap).and_yield(file)
    end

    it 'writes the transaction to file' do
      repository.add(transaction)

      expect(file.tap(&:rewind).read).to eq(transaction.to_file + "\n")
    end
  end

  describe '#convert!' do
    subject { repository.convert! }

    let(:path) { File.join('spec', 'fixtures', 'multiple-currencies.csv') }
    let(:file) { instance_double('File') }
    let(:csv) { instance_double('CSV') }

    let(:transactions) do
      [
        t(
          keys.map(&:to_sym).zip(
            ['Main', '2018-06-23', 'Category B', 'Initial Balance', nil, '+15.50', 'USD', 'Travel D']
          ).to_h
        ),
        t(
          keys.map(&:to_sym).zip(
            ['Main', '2018-07-23', 'Category A', 'Description C', 'Venue E', '-11.60', 'USD', nil]
          ).to_h
        )
      ]
    end

    specify do
      expect(CSV).to receive(:open).with(path, 'wb').and_yield(csv).once
      expect(csv).to receive(:<<).with(keys.map(&:capitalize).map(&:to_sym))

      expect(File).to receive(:open).with(path, 'a').and_yield(file).twice
      transactions.each { |transaction| expect(file).to receive(:write).with("#{transaction.to_file}\n") }

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
        let(:keys) { %w[date invested investment amount currency] }

        specify do
          expect(CSV).to receive(:open).with(filepath, 'wb').and_yield(csv)
          expect(csv).to receive(:<<).with(keys.map(&:capitalize).map(&:to_sym))
          expect(Ledger::Encryption).to receive(:new).with(filepath).and_return(encryption)

          subject
        end
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
        .with("echo \"#{transactions[0].to_file}\" >> /dev/stdout")
      expect_any_instance_of(Kernel)
        .to receive(:system)
        .with("echo \"#{transactions[1].to_file}\" >> /dev/stdout")

      subject
    end

    context 'when a date is defined' do
      let(:options) { super().merge(from: Date.new(2018, 6, 28), till: Date.new(2018, 9, 28)) }

      specify do
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{transactions[1].to_file}\" >> /dev/stdout")

        subject
      end
    end

    context 'when a currency is defined' do
      let(:options) { super().merge(currency: 'BBD') }

      let(:result) { transactions.map { |t| t.exchange_to(options[:currency]).to_file } }

      specify do
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{result[0]}\" >> /dev/stdout")
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{result[1]}\" >> /dev/stdout")

        subject
      end
    end

    context 'when networth is defined' do
      let(:options) { super().merge(networth: true) }
      let(:result) do
        [
          Ledger::Networth.new(date: '2018-06-23', invested: '+1.00', investment: '+5.00', amount: '+15.50', currency: 'USD'),
          Ledger::Networth.new(date: '2018-07-23', invested: '+0.00', investment: '+4.50', amount: '-10.00', currency: 'USD')
        ].map(&:to_file)
      end

      specify do
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{result[0]}\" >> /dev/stdout")
        expect_any_instance_of(Kernel)
          .to receive(:system)
          .with("echo \"#{result[1]}\" >> /dev/stdout")

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
    let(:csv) { instance_double('CSV') }
    let(:keys) { %w[date invested investment amount currency] }

    let(:networth_entries) do
      [
        Ledger::Networth.new(keys.map(&:to_sym).zip(['2018-06-23', Money.new(0, 'USD'), '+5.00', '+15.50', 'USD']).to_h),
        Ledger::Networth.new(keys.map(&:to_sym).zip(['2018-07-23', Money.new(0, 'USD'), '+4.50', '-10.00', 'USD']).to_h)
      ]
    end

    specify do
      expect_any_instance_of(Ledger::Content).to receive(:current_networth).and_return(networth)
      expect(CSV).to receive(:open).with(networth_path, 'wb').and_yield(csv).once
      expect(csv).to receive(:<<).with(keys.map(&:capitalize).map(&:to_sym))

      expect(File).to receive(:open).with(networth_path, 'a').and_yield(file).exactly(3).times
      networth_entries.each { |entry| expect(file).to receive(:write).with("#{entry.to_file}\n") }

      expect(file).to receive(:write).with("to_file\n")

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
