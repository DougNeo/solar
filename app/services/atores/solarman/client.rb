module Atores
  module Solarman
    class Client
      BASE_URL = "https://globalapi.solarmanpv.com/".freeze

      def initialize(url = BASE_URL)
        @url = url
        @conn = Faraday.new(url: url) do |conn|
          configure_connection(conn)
        end
      end

      def exec_get(path, params = {}, headers = {})
        response = @conn.get(path, params) do |request|
          request.headers = headers
        end
        JSON.parse(response.body)
      end

      def exec_post(path, body = {}, params = {}, headers = {})
        @conn.post(url, params) do |conn|
          headers.each do |key, value|
            conn.headers[key] = value
          end
        conn.body = body
        conn
        end
      end

      def configure_connection(conn)
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end
  end
end