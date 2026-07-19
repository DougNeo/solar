require "test_helper"

class SolarmanClientTest < ActiveSupport::TestCase
  Response = Struct.new(:status, :body) { def success? = status.between?(200, 299) }
  Connection = Struct.new(:response) do
    def post(_path)
      request = Struct.new(:params, :headers, :body).new({}, {}, nil)
      yield request
      response
    end
  end

  test "parses successful payload" do
    client = Atores::Solarman::Client.new(connection: Connection.new(Response.new(200, '{"stationList":[]}')))
    assert_equal [], client.post("/station", body: {})["stationList"]
  end

  test "raises safe HTTP error" do
    client = Atores::Solarman::Client.new(connection: Connection.new(Response.new(500, '{"secret":"must-not-leak"}')))
    error = assert_raises(Atores::Solarman::ApiError) { client.post("/station", body: {}) }
    refute_includes error.message, "secret"
  end

  test "recognizes expired token" do
    client = Atores::Solarman::Client.new(connection: Connection.new(Response.new(401, "{}")))
    assert_raises(Atores::Solarman::AuthenticationError) { client.post("/station", body: {}) }
  end
end
