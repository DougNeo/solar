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
    debugger
    path = "/station/v1.0/list"
    params = {
      "appId": ENV["SOLARMAN_APP_ID"],
      "language": "en"
    }
    headers = {
      "Authorization" => "Bearer #{@token}"
    }
    body = {}

    @client.post(path, body, params, headers)
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

    response = @client.post(path, body, params, headers)
    OpenStruct.new(JSON.parse(response.body))
   end
  end
 end
end
