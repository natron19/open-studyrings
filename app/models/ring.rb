class Ring < ApplicationRecord
  belongs_to :user
  has_one    :learning_charter, dependent: :destroy
  has_many   :ring_sessions, through: :learning_charter

  MEMBER_BACKGROUNDS  = %w[beginner mixed experienced].freeze
  MEETING_FREQUENCIES = %w[weekly biweekly].freeze
  STATUSES            = %w[draft generating complete failed].freeze

  validates :topic,             presence: true, length: { minimum: 5, maximum: 200 }
  validates :member_background, presence: true, inclusion: { in: MEMBER_BACKGROUNDS }
  validates :meeting_frequency, presence: true, inclusion: { in: MEETING_FREQUENCIES }
  validates :purpose,           presence: true, length: { minimum: 10, maximum: 500 }
  validates :status,            inclusion: { in: STATUSES }

  scope :ordered, -> { order(created_at: :desc) }
end
