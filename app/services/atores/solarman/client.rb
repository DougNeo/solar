module Atores
  module Solarman
    class Client
      BASE_URL = "https://globalapi.solarmanpv.com/".freeze

      def initialize(url = BASE_URL)
        @conn = Faraday.new(url: url) do |conn|
          configure_connection(conn)
        end
      end

      def post(path, body)
        @conn.post(path, body)
      end

      def configure_connection(conn)
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end
  end
end