class LearningCharter < ApplicationRecord
  belongs_to :ring
  has_many   :ring_sessions, dependent: :destroy

  validates :ring_id,    presence: true, uniqueness: true
  validates :gemini_raw, presence: true

  def learning_goals_list
    learning_goals.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def success_indicators_list
    success_indicators.to_s.split("\n").map(&:strip).reject(&:blank?)
  end
end
