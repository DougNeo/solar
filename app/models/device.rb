class Device < ApplicationRecord
  belongs_to :plant
  has_many :alerts, dependent: :nullify

  validates :serial, presence: true, uniqueness: true

  def online?
    status.to_s.downcase.in?(%w[normal online 1])
  end
end
