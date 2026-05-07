class RingSession < ApplicationRecord
  belongs_to :learning_charter
  has_one    :ring, through: :learning_charter

  validates :week_number,      presence: true,
                               inclusion: { in: 1..6 },
                               uniqueness: { scope: :learning_charter_id }
  validates :guiding_question, presence: true

  def resources_list
    resources.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def discussion_prompts_list
    discussion_prompts.to_s.split("\n").map(&:strip).reject(&:blank?)
  end
end
