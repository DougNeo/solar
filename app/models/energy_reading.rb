class EnergyReading < ApplicationRecord
  belongs_to :plant
  validates :recorded_on, presence: true, uniqueness: { scope: :plant_id }
end
