FactoryBot.define do
  factory :ring_session do
    learning_charter
    week_number        { 1 }
    guiding_question   { "What do we mean when we say 'peer learning'?" }
    resources          { "The Peer Learning Handbook (PDF)\nCommunity of Practice by Wenger (book excerpt)" }
    discussion_prompts { "When did you last learn something from a peer?\nWhat made it stick?\nHow is this different from instruction?" }
    inquiry_activity   { "Each member shares one example; group maps common themes." }
  end
end
