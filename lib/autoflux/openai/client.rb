# frozen_string_literal: true

require "net/http"
require "json"

module Autoflux
  module OpenAI
    # The minimal completion api client to interact with OpenAI
    class Client
      DEFAULT_ENDPOINT = URI("https://api.openai.com/v1/chat/completions")

      def initialize(api_key: nil, endpoint: DEFAULT_ENDPOINT)
        @api_key = ENV.fetch("OPENAI_API_KEY", api_key)
        @endpoint = endpoint
      end

      def call(payload)
        res = http.post(@endpoint.path || "", payload.to_json, headers)
        raise error_of(res), res.body unless res.is_a?(Net::HTTPSuccess)

        JSON.parse(res.body, symbolize_names: true)
      rescue JSON::ParserError
        {}
      end

      protected

      def headers
        @headers ||= {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@api_key}"
        }
      end

      def error_of(res)
        case res
        when Net::HTTPUnauthorized then AuthoriztionError
        when Net::HTTPBadRequest then BadRequestError
        when Net::HTTPTooManyRequests then RateLimitError
        else Error
        end
      end

      def http
        @http ||= Net::HTTP.new(@endpoint.host || "", @endpoint.port).tap do |http|
          http.use_ssl = @endpoint.scheme == "https"
        end
      end
    end
  end
end
