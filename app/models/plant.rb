class Plant < ApplicationRecord
  has_many :devices, dependent: :destroy
  has_many :energy_readings, dependent: :destroy
  has_many :alerts, dependent: :destroy

  validates :plant_id, presence: true, uniqueness: true

  def stale?(at: 5.minutes.ago)
    last_synced_at.nil? || last_synced_at < at
  end
end
