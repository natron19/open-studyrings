FactoryBot.define do
  factory :ring do
    user
    topic             { "The role of peer learning in open source communities" }
    member_background { "mixed" }
    meeting_frequency { "weekly" }
    purpose           { "We want to understand how people learn together without a teacher." }
    status            { "draft" }

    trait :complete do
      status { "complete" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :generating do
      status { "generating" }
    end
  end
end
