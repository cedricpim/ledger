module Ledger
  # Module responsible for encapsulating queries to other services
  module API
    # Class responsible for fetching the page of justETF service for a given
    # ETF and get the current code by parsing the HTML response
    class JustETF
      ENDPOINT = 'https://www.justetf.com/de-en/etf-profile.html'.freeze
      TITLE_CSS = '.h1'.freeze
      QUOTE_CSS = 'div.val span'.freeze

      class InvalidResponseError < StandardError; end
      class MissingQuoteError < StandardError; end

      attr_reader :isin

      def initialize(isin:)
        @isin = isin
      end

      def title
        document.at(TITLE_CSS).content.split("\n").first
      end

      def quote
        currency, value = document.css(QUOTE_CSS).first(2).map(&:content)

        raise MissingQuoteError, "#{value} #{currency}" unless valid_info?(currency, value)

        Money.new(BigDecimal(value) * 100, currency)
      end

      private

      def document
        @document ||= begin
          response = Faraday.get(ENDPOINT, isin: isin)

          raise InvalidResponseError, response.body unless response.success?

          Nokogiri::HTML(response.body)
        end
      end

      def valid_info?(currency, value)
        currency && !currency.empty? && value && !value.empty?
      end
    end
  end
end
