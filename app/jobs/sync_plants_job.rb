class SyncPlantsJob < ApplicationJob
  queue_as :default

  def perform
    sync = SolarmanSync.new
    sync.plants!
    Plant.find_each { |plant| sync.devices!(plant) }
  end
end
