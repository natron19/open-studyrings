# Phase 2 — Data Models

**Goal:** Create the three domain models — `Ring`, `LearningCharter`, `RingSession` — with migrations, validations, associations, helper methods, and RSpec factories.

**Depends on:** Phase 1 complete. Boilerplate database running with `pgcrypto` extension enabled.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Section 3, Section 9

---

## Context

All three models use UUID primary keys (`pgcrypto` extension, inherited from boilerplate convention). All timestamps are `null: false`. Boolean columns have `default: false, null: false`.

`learning_goals`, `success_indicators`, `resources`, and `discussion_prompts` are stored as **newline-delimited text** — not arrays, not JSONB. Helper methods on the models split on `\n` at read time. This is a deliberate tradeoff to keep the model count to three.

The `Ring` model is the top-level domain object. A `LearningCharter` is one-to-one with a `Ring` and is created only after Gemini runs. Six `RingSession` records belong to a `LearningCharter`.

---

## Tasks

### 2.1 — Migration: `rings` table

```ruby
create_table :rings, id: :uuid do |t|
  t.references :user,               null: false, foreign_key: true, type: :uuid
  t.string     :topic,              null: false
  t.string     :member_background,  null: false
  t.string     :meeting_frequency,  null: false
  t.text       :purpose,            null: false
  t.string     :status,             null: false, default: "draft"
  t.timestamps                      null: false
end
add_index :rings, :user_id
add_index :rings, :status
```

### 2.2 — Migration: `learning_charters` table

```ruby
create_table :learning_charters, id: :uuid do |t|
  t.references :ring,               null: false, foreign_key: true, type: :uuid
  t.text       :focus_statement
  t.text       :learning_goals
  t.text       :success_indicators
  t.text       :inquiry_framework
  t.text       :invite_suggestions
  t.text       :artifact_template
  t.text       :gemini_raw,         null: false
  t.timestamps                      null: false
end
add_index :learning_charters, :ring_id, unique: true
```

### 2.3 — Migration: `ring_sessions` table

```ruby
create_table :ring_sessions, id: :uuid do |t|
  t.references :learning_charter,   null: false, foreign_key: true, type: :uuid
  t.integer    :week_number,        null: false
  t.text       :guiding_question,   null: false
  t.text       :resources
  t.text       :discussion_prompts
  t.text       :inquiry_activity
  t.timestamps                      null: false
end
add_index :ring_sessions, :learning_charter_id
add_index :ring_sessions, [:learning_charter_id, :week_number], unique: true
```

### 2.4 — Run migrations

```bash
bin/rails db:migrate
```

Verify: `bin/rails db:schema:dump` and confirm all three tables appear in `db/schema.rb`.

### 2.5 — `app/models/ring.rb`

```ruby
class Ring < ApplicationRecord
  belongs_to :user
  has_one    :learning_charter, dependent: :destroy
  has_many   :ring_sessions, through: :learning_charter

  MEMBER_BACKGROUNDS  = %w[beginner mixed experienced].freeze
  MEETING_FREQUENCIES = %w[weekly biweekly].freeze
  STATUSES            = %w[draft generating complete failed].freeze

  validates :topic,              presence: true, length: { minimum: 5, maximum: 200 }
  validates :member_background,  presence: true, inclusion: { in: MEMBER_BACKGROUNDS }
  validates :meeting_frequency,  presence: true, inclusion: { in: MEETING_FREQUENCIES }
  validates :purpose,            presence: true, length: { minimum: 10, maximum: 500 }
  validates :status,             inclusion: { in: STATUSES }

  scope :ordered, -> { order(created_at: :desc) }
end
```

### 2.6 — `app/models/learning_charter.rb`

```ruby
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
```

### 2.7 — `app/models/ring_session.rb`

```ruby
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
```

### 2.8 — `spec/factories/rings.rb`

```ruby
FactoryBot.define do
  factory :ring do
    user
    topic             { "The role of peer learning in open source communities" }
    member_background { "mixed" }
    meeting_frequency { "weekly" }
    purpose           { "We want to understand how people learn together without a teacher." }
    status            { "draft" }

    trait :complete   { status { "complete" } }
    trait :failed     { status { "failed" } }
    trait :generating { status { "generating" } }
  end
end
```

### 2.9 — `spec/factories/learning_charters.rb`

```ruby
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
```

### 2.10 — `spec/factories/ring_sessions.rb`

```ruby
FactoryBot.define do
  factory :ring_session do
    learning_charter
    week_number      { 1 }
    guiding_question { "What do we mean when we say 'peer learning'?" }
    resources        { "The Peer Learning Handbook (PDF)\nCommunity of Practice by Wenger (book excerpt)" }
    discussion_prompts { "When did you last learn something from a peer?\nWhat made it stick?\nHow is this different from instruction?" }
    inquiry_activity { "Each member shares one example; group maps common themes." }
  end
end
```

---

## Manual Tests

Run these in `bin/rails console`:

```ruby
u = User.find_by(email: "demo@example.com")

# Create a ring
r = Ring.create!(user: u, topic: "Test topic here", member_background: "mixed",
                 meeting_frequency: "weekly", purpose: "We want to test this works.")
puts r.valid?    # => true
puts r.status    # => "draft"

# Create a charter
c = LearningCharter.create!(
  ring: r,
  gemini_raw: '{}',
  focus_statement: "Test",
  learning_goals: "Goal 1\nGoal 2",
  success_indicators: "Indicator 1",
  inquiry_framework: "Framework",
  invite_suggestions: "Invite someone",
  artifact_template: "Make a doc"
)
puts c.valid?                   # => true
puts c.learning_goals_list      # => ["Goal 1", "Goal 2"]

# Create a session
s = RingSession.create!(
  learning_charter: c, week_number: 1,
  guiding_question: "What is this?",
  resources: "Book A\nBook B",
  discussion_prompts: "Q1\nQ2\nQ3",
  inquiry_activity: "Do something."
)
puts s.valid?           # => true
puts s.resources_list   # => ["Book A", "Book B"]
puts r.ring_sessions.count  # => 1

# Validate uniqueness constraint on week_number
s2 = RingSession.new(learning_charter: c, week_number: 1, guiding_question: "Dupe?")
puts s2.valid?                  # => false
puts s2.errors.full_messages    # => includes "Week number has already been taken"

# Validate cascade destroy
c_id = c.id
r.destroy
puts LearningCharter.exists?(c_id)  # => false
puts RingSession.exists?(s.id)      # => false
```

---

## RSpec Tests

Create `spec/models/ring_spec.rb`, `spec/models/learning_charter_spec.rb`, and `spec/models/ring_session_spec.rb` before running.

```bash
bundle exec rspec spec/models/ring_spec.rb spec/models/learning_charter_spec.rb spec/models/ring_session_spec.rb
```

### `spec/models/ring_spec.rb` — required coverage

- `topic` presence validation
- `topic` length minimum (4 chars fails, 5 chars passes)
- `topic` length maximum (201 chars fails, 200 chars passes)
- `member_background` inclusion — `"beginner"`, `"mixed"`, `"experienced"` pass; `"expert"` fails
- `meeting_frequency` inclusion — `"weekly"`, `"biweekly"` pass; `"daily"` fails
- `purpose` presence validation
- `purpose` length minimum (9 chars fails) and maximum (501 chars fails)
- `status` inclusion — all four valid statuses pass; `"pending"` fails
- Default `status` is `"draft"`
- `belongs_to :user` association
- `has_one :learning_charter, dependent: :destroy`
- Destroying a ring destroys its charter and all sessions

### `spec/models/learning_charter_spec.rb` — required coverage

- `ring_id` presence validation
- `ring_id` uniqueness (two charters for same ring fails)
- `gemini_raw` presence validation
- `has_many :ring_sessions, dependent: :destroy`
- `learning_goals_list` splits `"Goal 1\nGoal 2\nGoal 3"` into three-element array
- `learning_goals_list` filters blank lines
- `success_indicators_list` same behavior

### `spec/models/ring_session_spec.rb` — required coverage

- `week_number` inclusion — 1 through 6 pass; 0 and 7 fail
- `week_number` uniqueness scoped to `learning_charter_id` — same week_number in different charters passes; same week_number in same charter fails
- `guiding_question` presence validation
- `resources_list` splits on newlines, filters blanks
- `discussion_prompts_list` same behavior

---

## Acceptance Criteria

- [ ] All three migrations run cleanly; tables present in `db/schema.rb`
- [ ] `Ring` model: all validations pass/fail as specified; associations correct; cascade destroy verified
- [ ] `LearningCharter` model: uniqueness on `ring_id`; helper methods return arrays
- [ ] `RingSession` model: week_number scoped uniqueness; helper methods return arrays
- [ ] All three factory files created and usable (`FactoryBot.create(:ring)` succeeds)
- [ ] All three model spec files pass with zero failures
