require "ostruct"
module Atores
 module Solarman
  class Request
   include Atores::Solarman::Helpers


   def initialize(client = nil)
    @client = client || Atores::Solarman::Client.new
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
    OpenStruct.new(JSON.parse(response.body))
   end

   def plant_list
    debugger
    path = "/station/v1.0/list"
    params = {
      "appId": ENV["SOLARMAN_APP_ID"],
      "language": "en"
    }
    body = {
      "token": token
    }
    @client.post(path, body, params)
   end
  end
 end
end
