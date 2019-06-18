RSpec.describe Ledger::Printers::Balance do
  subject(:printer) { described_class.new(total: total) }

  let(:total) { proc {} }

  describe '#call' do
    let(:data) { [{title: 'Title', value: Money.new(5)}, {title: 'Title Nil', value: nil}] }

    let(:header_options) { {align: 'center', bold: true, color: :cyan, rule: true, title: 'Balance', width: 70} }

    let(:row_options) { {width: 40, align: 'right', padding: 5} }

    specify do
      expect(printer).to receive(:header).with(header_options)
      expect(printer).to receive(:row).with(color: :blue, bold: true).and_yield
      expect(printer).to receive(:row).with(color: :white).and_yield
      expect(printer).to receive(:column).with('Account', row_options)
      expect(printer).to receive(:column).with('Amount', row_options.merge(align: 'left'))
      expect(printer).to receive(:column).with('Title', row_options)
      expect(printer).to receive(:column).with('0.05$', row_options.merge(align: 'left', color: :green))
      expect(total).to receive(:call)

      printer.call(data)
    end
  end
end
