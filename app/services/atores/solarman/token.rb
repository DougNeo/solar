module Atores
 module Solarman
  class Token
   def initialize(client)
    @client = client
   end

   def get
    path = "account/v1.0/token"
    params = { "appId": ENV["SOLARMAN_APP_ID"] }
    body = {
     "appSecret": ENV["SOLARMAN_APP_SECRET"],
     "password": password_encrypted
   }.to_json
    @client.post(path, body) do |request|
      request.params = params
    end
   end

   def password_encrypted
    Digest::SHA256.hexdigest(ENV["SOLARMAN_PASSWORD"])
   end
  end
 end
end
