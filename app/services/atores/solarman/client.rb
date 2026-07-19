module Atores
  module Solarman
    class Client
      BASE_URL = "https://globalapi.solarmanpv.com"

      def initialize(url: BASE_URL, connection: nil)
        @connection = connection || Faraday.new(url:) do |faraday|
          faraday.request :json
          faraday.options.open_timeout = 5
          faraday.options.timeout = 15
        end
      end

      def post(path, body:, params: {}, token: nil)
        response = @connection.post(path) do |request|
          request.params.update(params)
          request.headers["Authorization"] = "Bearer #{token}" if token
          request.headers["Accept"] = "application/json"
          request.body = body
        end
        parse(response)
      rescue Faraday::Error => error
        Rails.logger.warn("Solarman transport error: #{error.class}")
        raise TransportError, "Não foi possível conectar à Solarman"
      end

      private

      def parse(response)
        payload = JSON.parse(response.body.presence || "{}")
        raise AuthenticationError, "Token Solarman expirado" if response.status == 401 || payload["code"].to_s.in?(%w[2101002 2101004])
        raise ApiError, "Solarman HTTP #{response.status}" unless response.success?
        raise ApiError, payload["msg"].presence || "Erro retornado pela Solarman" if payload["success"] == false || payload["code"].to_i.positive?

        payload
      rescue JSON::ParserError
        raise ApiError, "Resposta inválida da Solarman"
      end
    end
  end
end
