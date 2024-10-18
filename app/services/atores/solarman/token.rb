module Atores
  module Solarman
    class Token
      def initialize(client = nil)
        @client = client || Atores::Solarman::Client.new
      end

      def get
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
        @client.post(path, body, params)
      end

      def password_encrypted
        Digest::SHA256.hexdigest(ENV["SOLARMAN_PASSWORD"])
      end
    end
  end
end
