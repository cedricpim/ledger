RSpec.describe Ledger::API::JustETF do
  subject(:just_etf) { described_class.new(isin: isin) }

  let(:isin) { 'IE00B945VV12' }

  describe '#quote' do
    subject { just_etf.quote }

    context 'when valid response', vcr: {cassette_name: 'just_etf_quote'} do
      it { is_expected.to eq Money.new(2970, 'EUR') }
    end

    context 'when invalid response', vcr: {cassette_name: 'just_etf_quote-not_found'} do
      before { stub_const("#{described_class}::ENDPOINT", 'https://www.justetf.com/de-en/page-not-found.html') }

      specify do
        expect { just_etf.quote }.to raise_error(described_class::InvalidResponseError)
      end
    end

    context 'when invalid response', vcr: {cassette_name: 'just_etf_quote-missing_quote'} do
      before { stub_const("#{described_class}::ENDPOINT", 'https://www.justetf.com/de-en/find-etf.html') }

      specify do
        expect { just_etf.quote }.to raise_error(described_class::MissingQuoteError)
      end
    end
  end
end
