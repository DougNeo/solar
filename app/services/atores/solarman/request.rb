module Atores
  module Solarman
    class Request
      include Helpers

      Station = Data.define(:id, :name, :latitude, :longitude, :address, :installed_capacity, :start_operating_time, :raw)
      Reading = Data.define(:date, :generation_kwh, :raw)

      def initialize(client: Client.new, token_provider: nil)
        @client = client
        @token_provider = token_provider || Token.new(client:)
      end

      def stations
        paginate("/station/v1.0/list", {}, "stationList").map do |item|
          Station.new(id: item["id"].to_s, name: item["name"], latitude: item["locationLat"], longitude: item["locationLng"],
            address: item["locationAddress"], installed_capacity: item["installedCapacity"],
            start_operating_time: parse_time(item["startOperatingTime"]), raw: item)
        end
      end

      def station_base(station_id) = authenticated_post("/station/v1.0/base", stationId: station_id)
      def real_time(station_id) = authenticated_post("/station/v1.0/realTime", stationId: station_id)
      def devices(station_id) = paginate("/station/v1.0/device", { stationId: station_id }, "deviceList")
      def alerts(station_id, start_date: 30.days.ago.to_date, end_date: Date.current)
        paginate(
          "/station/v1.0/alert",
          {
            stationId: station_id,
            startTime: start_date.to_date.iso8601,
            endTime: end_date.to_date.iso8601
          },
          "stationAlertItems"
        )
      end
      def current_data(device_sn) = authenticated_post("/device/v1.0/currentData", deviceSn: device_sn)
      def alert_detail(device_sn:, alert_id:) = authenticated_post("/device/v1.0/alertDetail", deviceSn: device_sn, alertId: alert_id)

      def history(station_id, start_date, end_date)
        raise ArgumentError, "A janela histórica não pode ultrapassar 30 dias" if (end_date.to_date - start_date.to_date).to_i > 29

        payload = authenticated_post("/station/v1.0/history", stationId: station_id, startTime: start_date.to_date.iso8601,
          endTime: end_date.to_date.iso8601, timeType: 2)
        Array(payload["stationDataItems"]).map do |item|
          date = Date.new(item["year"].to_i, item["month"].to_i, item["day"].to_i)
          Reading.new(date:, generation_kwh: item["generationValue"], raw: item)
        end
      end

      private

      def paginate(path, body, key)
        page = 1
        results = []
        loop do
          payload = authenticated_post(path, **body, page: page, size: 100)
          items = Array(payload[key])
          results.concat(items)
          total = payload["total"].to_i
          break if items.empty? || items.length < 100 || (total.positive? && results.length >= total)
          page += 1
        end
        results
      end

      def authenticated_post(path, **body)
        attempts = 0
        begin
          @client.post(path, body:, params: default_params, token: @token_provider.value(force: attempts.positive?))
        rescue AuthenticationError
          attempts += 1
          retry if attempts == 1
          raise
        end
      end

      def default_params
        { appId: credentials.fetch(:app_id), language: "pt" }
      end

      def parse_time(value)
        raw_value = value.to_s
        if raw_value.match?(/\A\d{10,13}\z/)
          seconds = raw_value.to_i
          seconds /= 1000 if raw_value.length == 13
          return Time.at(seconds).in_time_zone
        end

        Time.zone.parse(value.to_s) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
