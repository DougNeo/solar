class SyncHistoryJob < ApplicationJob
  queue_as :default
  def perform
    sync = SolarmanSync.new
    Plant.find_each { |plant| sync.history!(plant) }
  end
end
