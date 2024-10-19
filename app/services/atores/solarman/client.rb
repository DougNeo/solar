module Atores
  module Solarman
    class Client
      BASE_URL = "https://globalapi.solarmanpv.com".freeze

      def initialize(url = BASE_URL)
        @conn = Faraday.new(url: url) do |conn|
          conn.request :json
        end
      end

      def post(path, body, query_params = {}, headers = {})
        @conn.post(path) do |req|
          req.body = body
          req.params = query_params unless query_params.empty?
          req.headers = headers
        end
      end
    end
  end
end
