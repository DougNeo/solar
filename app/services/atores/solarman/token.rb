module Atores
  module Solarman
    class Token
      include Helpers

      CACHE_KEY = "solarman/access_token"

      def initialize(client: Client.new)
        @client = client
      end

      def value(force: false)
        Rails.cache.delete(CACHE_KEY) if force
        Rails.cache.read(CACHE_KEY) || fetch_token
      end

      def invalidate!
        Rails.cache.delete(CACHE_KEY)
      end

      private

      def fetch_token
        payload = @client.post("/account/v1.0/token", params: default_params, body: {
          appSecret: credentials.fetch(:app_secret), email: credentials.fetch(:email), password: password_encrypted
        })
        token = payload.fetch("access_token")
        lifetime = [ payload.fetch("expires_in", 3600).to_i - 60, 60 ].max
        Rails.cache.write(CACHE_KEY, token, expires_in: lifetime)
        token
      rescue KeyError
        raise AuthenticationError, "Resposta de autenticação da Solarman incompleta"
      end

      def default_params
        { appId: credentials.fetch(:app_id), language: "pt" }
      end
    end
  end
end
