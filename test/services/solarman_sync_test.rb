require "test_helper"

class SolarmanSyncTest < ActiveSupport::TestCase
  FakeApi = Struct.new(:history_calls) do
    def stations = []
    def devices(_id) = []
    def alerts(_id) = []
    def history(_id, first, last)
      history_calls << [ first, last ]
      (first..last).map { |date| Atores::Solarman::Request::Reading.new(date:, generation_kwh: 4, raw: {}) }
    end
  end

  test "imports non-overlapping windows and remains idempotent" do
    plant = Plant.create!(plant_id: "p1", start_operating_time: Time.zone.local(2026, 1, 1))
    api = FakeApi.new([])
    sync = SolarmanSync.new(api: api)
    sync.history!(plant, through: Date.new(2026, 2, 5))
    assert_equal [ [ Date.new(2026, 1, 1), Date.new(2026, 1, 30) ], [ Date.new(2026, 1, 31), Date.new(2026, 2, 5) ] ], api.history_calls
    assert_equal 36, plant.energy_readings.count
    sync.history!(plant, through: Date.new(2026, 2, 5))
    assert_equal 36, plant.energy_readings.count
  end
end
