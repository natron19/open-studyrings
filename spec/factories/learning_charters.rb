FactoryBot.define do
  factory :learning_charter do
    ring
    focus_statement    { "This ring explores peer learning dynamics." }
    learning_goals     { "Understand peer learning theory\nApply inquiry techniques\nProduce a shared artifact" }
    success_indicators { "Members can explain core concepts\nRing completes Week 6 artifact\nGroup feels more connected" }
    inquiry_framework  { "Use the 3-lens model: personal, relational, systemic." }
    invite_suggestions { "Invite a community organizer in Week 4. A practitioner from an open source project in Week 5." }
    artifact_template  { "A one-page synthesis document: what we learned and what we'd do differently." }
    gemini_raw         { '{"focus_statement":"This ring explores peer learning dynamics."}' }
  end
end
