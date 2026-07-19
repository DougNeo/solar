require "test_helper"

class SolarmanRequestTest < ActiveSupport::TestCase
  FakeToken = Struct.new(:calls) do
    def value(force: false)
      calls << force
      "token"
    end
  end

  class FakeClient
    attr_reader :calls
    def initialize(payloads) = (@payloads = payloads; @calls = [])
    def post(path, **options)
      @calls << [ path, options ]
      result = @payloads.shift
      raise result if result.is_a?(Exception)
      result
    end
  end

  test "retries authentication only once" do
    client = FakeClient.new([ Atores::Solarman::AuthenticationError.new, { "stationList" => [] } ])
    token = FakeToken.new([])
    request = Atores::Solarman::Request.new(client: client, token_provider: token)
    request.define_singleton_method(:credentials) { { app_id: "app" } }
    assert_empty request.stations
    assert_equal [ false, true ], token.calls
  end

  test "preserves missing station fields as nil" do
    client = FakeClient.new([ { "stationList" => [ { "id" => 3 } ], "total" => 1 } ])
    request = Atores::Solarman::Request.new(client: client, token_provider: FakeToken.new([]))
    request.define_singleton_method(:credentials) { { app_id: "app" } }
    station = request.stations.first
    assert_nil station.name
    assert_equal "3", station.id
  end

  test "rejects a history window over 30 inclusive days" do
    request = Atores::Solarman::Request.new(client: FakeClient.new([]), token_provider: FakeToken.new([]))
    assert_raises(ArgumentError) { request.history("1", Date.new(2026, 1, 1), Date.new(2026, 1, 31)) }
  end
end
