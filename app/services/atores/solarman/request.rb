require "ostruct"
module Atores
  module Solarman
    class Request
      def initialize
        @client = Atores::Solarman::Client.new
        token = Atores::Solarman::Token.new
        @token = token.saved_token
      end

      def plant_list
        path = "/station/v1.0/list"
        params = {
          "appId": ENV["SOLARMAN_APP_ID"],
          "language": "en"
        }
        headers = {
          "Authorization" => "Bearer #{@token}"
        }
        body = {}

        response = @client.post(path, body, params, headers)
        parsed = JSON.parse(response.body, object_class: OpenStruct)

        parsed.stationList.each do |plant|
          Plant.find_or_create_by(plant_id: plant.id) do |p|
            p.name = plant.name
            p.latitude = plant.locationLat
            p.longitude = plant.locationLng
            p.address = plant.locationAddress
            p.installed_capacity = plant.installedCapacity
            p.start_operating_time = plant.startOperatingTime
          end
        end
      end

      def historical_data(plant_id, start_time, end_time = Date.today.to_s)
        path = "/station/v1.0/history"
        params = {
          "appId": ENV["SOLARMAN_APP_ID"],
          "language": "en"
        }
        headers = {
          "Authorization" => "Bearer #{@token}"
        }
        body = {
          "stationId": plant_id,
          "startTime": start_time,
          "endTime": end_time,
          "timeType": 2
        }
        begin
        response = @client.post(path, body, params, headers)
        JSON.parse(response.body, object_class: OpenStruct)
        rescue => e
          puts "O retorno da request foi #{response.body}"
          puts "O erro foi #{e}"
        end
      end

      def get_all_data(plant_id, start_time = "2024-04-19", end_time = Date.today.to_s)
        dados = []
        inicio = Date.parse(start_time)
        fim = Date.parse(end_time)

        while inicio < fim
          puts "Buscando dados de #{inicio} a #{inicio + 30.days}"
          parsed = historical_data(plant_id, inicio.to_s, (inicio + 30.days).to_s)
          parsed.stationDataItems.each do |item|
            dados << dia = {
              date: Date.new(item.year, item.month, item.day),
              generation_value: item.generationValue
            }
          end
          inicio += 30.days
        end
        dados
      end
    end
  end
end
