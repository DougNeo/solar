class Alert < ApplicationRecord
  belongs_to :plant
  belongs_to :device, optional: true
  validates :external_id, presence: true, uniqueness: true

  scope :recent_first, -> { order(occurred_at: :desc) }
end
