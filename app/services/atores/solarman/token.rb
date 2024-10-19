module Atores
  module Solarman
    class Token
      include Atores::Solarman::Helpers
      def initialize
        @client = Atores::Solarman::Client.new
      end

      def saved_token
        Rails.cache.fetch("solarman_token", expires_in: 60.days) do
          token
        end
      end

      def token
        path = "/account/v1.0/token"
        params = {
          "appId": ENV["SOLARMAN_APP_ID"],
          "language": "en"
        }
        body = {
          "appSecret": ENV["SOLARMAN_APP_SECRET"],
          "password": password_encrypted,
          "email": ENV["SOLARMAN_EMAIL"]
        }
        response = @client.post(path, body, params)
        if response.status != 200
          raise "Error: #{response.body}"
        end
        JSON.parse(response.body)["access_token"]
      end
    end
  end
end
