class SyncHistoryJob < ApplicationJob
  queue_as :default

  def perform
    sync = SolarmanSync.new
    through = Date.yesterday

    Plant.find_each do |plant|
      sync.history!(plant, start_date: history_start_for(plant, through), through:)
    end
  end

  private

  def history_start_for(plant, through)
    return [ through - 29.days, plant.start_operating_time&.to_date ].compact.max unless Rails.env.production?

    plant.energy_readings.maximum(:recorded_on)&.next || plant.start_operating_time&.to_date || through
  end
end
