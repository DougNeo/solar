require "test_helper"

class EnergyReadingTest < ActiveSupport::TestCase
  test "is unique by plant and date" do
    plant = Plant.create!(plant_id: "station-1")
    plant.energy_readings.create!(recorded_on: Date.current, generation_kwh: 2)
    duplicate = plant.energy_readings.new(recorded_on: Date.current, generation_kwh: 3)
    refute duplicate.valid?
  end
end
