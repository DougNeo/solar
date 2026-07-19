class SyncAlertsJob < ApplicationJob
  queue_as :default
  def perform
    sync = SolarmanSync.new
    Plant.find_each { |plant| sync.alerts!(plant) }
  end
end
