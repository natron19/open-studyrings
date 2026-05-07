# Phase 5 — AI Integration

**Goal:** Seed the `studyrings_curriculum_v1` AI template, implement the full `generate` action, create the JSON fixture for tests, and verify the end-to-end Gemini flow.

**Depends on:** Phase 4 complete. `RingsController#generate` currently redirects with a stub alert. `GeminiService`, `AiGatekeeper`, `AiBudgetChecker`, and `LlmRequest` are fully working from the boilerplate.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Sections 5, 7, 8, 9

---

## Context

The `generate` action is **synchronous** — the Gemini call runs inline in the request cycle. There are no background jobs. The 15-second timeout is the fallback for slow responses.

**Never call the Gemini API directly.** Always use `GeminiService.generate(template:, variables:)`. This ensures every call is gated, budgeted, logged, and time-bounded.

**Model:** Use `gemini-2.5-flash` in seeds. The spec document mentions `gemini-2.0-flash` in Section 7, but the boilerplate docs confirm `gemini-2.0-flash` is deprecated for new API keys. Always seed with `gemini-2.5-flash`.

**JSON parsing:** The response is a JSON string. Parse with `JSON.parse(response, symbolize_names: true)`. Store the raw unparsed response in `LearningCharter#gemini_raw`. If parsing fails, treat it as a `GeminiError`.

**Newline delimiter:** `learning_goals`, `success_indicators`, `resources`, and `discussion_prompts` are stored as newline-delimited text (joined with `\n` from the Gemini JSON arrays). Do not store as JSONB.

---

## Tasks

### 5.1 — Seed the AI template in `db/seeds.rb`

Replace or extend the existing seed. Use `find_or_create_by!` for idempotency.

```ruby
AiTemplate.find_or_create_by!(name: "studyrings_curriculum_v1") do |t|
  t.description       = "Generates a complete O.R.B.I.T. learning charter and 6-session curriculum for a peer learning ring, structured to climb Bloom's Taxonomy from Week 1 to Week 6."
  t.model             = "gemini-2.5-flash"
  t.max_output_tokens = 3000
  t.temperature       = 0.6

  t.system_prompt = <<~PROMPT
    You are an expert peer learning facilitator who designs curricula for self-organized
    study groups called "rings". A ring is 4 to 8 peers who meet to learn a topic
    together with no instructor.

    You produce curricula in the O.R.B.I.T. framework: Origin, Rhythm, Build, Invite,
    Transform. The framework treats learning as a cycle that returns rather than a line
    that ends. Origin defines focus and goals. Rhythm sets the structure of sessions
    and the 6-session arc. Build provides an inquiry framework the ring can apply in
    any session. Invite suggests external voices for weeks 4 and 5. Transform names
    the artifact the ring will produce by week 6.

    Your six sessions must climb Bloom's Taxonomy across the weeks:
    - Week 1: Remember and Understand (orientation, definitions, foundational reading)
    - Week 2: Understand and Apply (working with concepts, first practice)
    - Week 3: Apply and Analyze (deeper practice, breaking concepts apart)
    - Week 4: Analyze and Evaluate (critique, comparison, often with an outside voice)
    - Week 5: Evaluate and Create (synthesis with an outside voice)
    - Week 6: Create (the ring produces its artifact)

    You must respect member background:
    - "beginner": more reading, gentler analytic questions, foundational resources
    - "mixed": variety, with at least one resource accessible to beginners and at least one stretch resource each week
    - "experienced": skip orientation, assume vocabulary, push to evaluate and create earlier

    You must respect meeting frequency:
    - "weekly": tighter preparation expectations, smaller resource list per week
    - "biweekly": more preparation between sessions, larger resource list per week

    You produce inquiry questions, not lectures. Sessions are facilitated by peers, not
    taught. Resources are starting points for the ring's own collection, not required
    texts. The artifact is something the ring chooses to make together by week 6.

    You output ONLY valid JSON matching the schema provided. No prose before or after.
    No markdown code fences. No explanations. Just the JSON object.
  PROMPT

  t.user_prompt_template = <<~PROMPT
    Generate a complete O.R.B.I.T. learning curriculum for a peer learning ring.

    Inputs:
    - Topic: {{topic}}
    - Member background: {{member_background}}
    - Meeting frequency: {{meeting_frequency}}
    - Purpose: {{purpose}}

    Return a single JSON object with this exact shape:

    {
      "focus_statement": "<one paragraph naming what this ring is studying and why>",
      "learning_goals": [
        "<goal 1, stated as an outcome>",
        "<goal 2, stated as an outcome>",
        "<goal 3, stated as an outcome>"
      ],
      "success_indicators": [
        "<indicator 1>",
        "<indicator 2>",
        "<indicator 3>"
      ],
      "inquiry_framework": "<a short framework specific to the topic that the ring can apply in any session to go deeper>",
      "invite_suggestions": "<2 to 3 sentences on the kinds of guest perspectives or external voices to bring in during weeks 4 and 5>",
      "artifact_template": "<a description of one artifact the ring will produce by week 6>",
      "sessions": [
        {
          "week_number": 1,
          "guiding_question": "<one question that orbits the week's Bloom level>",
          "resources": ["<resource 1>", "<resource 2>"],
          "discussion_prompts": ["<prompt 1>", "<prompt 2>", "<prompt 3>"],
          "inquiry_activity": "<one collaborative activity description>"
        },
        { "week_number": 2 },
        { "week_number": 3 },
        { "week_number": 4 },
        { "week_number": 5 },
        { "week_number": 6 }
      ]
    }

    The "sessions" array must contain exactly 6 objects, in week_number order from 1 to 6.
  PROMPT

  t.notes = <<~NOTES
    The Bloom's progression is enforced by the system prompt; Gemini does not reason
    about it. Watch for: (1) Week 6 producing another reading list instead of an
    artifact; if so, tighten the artifact_template instruction. (2) Discussion
    prompts collapsing into closed yes/no questions for "beginner" rings; the prompt
    counters this but inspect output for it. (3) Invite suggestions becoming generic
    ("invite an expert"); push toward specific perspective types ("a practitioner
    who has implemented this in a small organization"). (4) JSON parse failures from
    trailing commentary; the "no prose before or after" instruction usually holds at
    temperature 0.6 but is not guaranteed. The controller catches JSON::ParserError
    and treats it as a Gemini error.
  NOTES
end

puts "Seeded: studyrings_curriculum_v1"
```

Run: `bin/rails db:seed`

### 5.2 — Create `spec/fixtures/studyrings_curriculum_response.json`

A complete valid sample JSON response matching the schema. This is used to stub `GeminiService.generate` in request specs. All six sessions must be present.

```json
{
  "focus_statement": "This ring explores how peer learning shapes knowledge in communities of practice, focusing on what happens when there is no instructor and learning emerges from shared inquiry.",
  "learning_goals": [
    "Articulate the difference between instructor-led and peer-facilitated learning",
    "Apply an inquiry framework to facilitate a peer session without a leader",
    "Produce a shared synthesis of what the ring learned and how it learned it"
  ],
  "success_indicators": [
    "Each member can explain the ring's core inquiry in their own words by Week 3",
    "The ring completes a Week 6 artifact collaboratively",
    "Members report feeling more connected to the topic after Week 6 than before Week 1"
  ],
  "inquiry_framework": "Use the Three Lenses: (1) Personal — what does this mean for me? (2) Relational — how does this affect the group? (3) Structural — what systems does this reveal?",
  "invite_suggestions": "In Week 4, invite a practitioner who runs peer-learning programs in a non-academic setting. In Week 5, invite someone who has participated in a ring or study group that failed — failure cases teach more than success stories.",
  "artifact_template": "A one-page synthesis document: what the ring studied, what it concluded, what it would do differently in a second ring on this topic, and one open question the ring did not resolve.",
  "sessions": [
    {
      "week_number": 1,
      "guiding_question": "What do we already believe about how people learn from each other, and where did those beliefs come from?",
      "resources": [
        "Situated Learning by Lave and Wenger (Chapter 1 excerpt, ~20 pages) — foundational framing of learning as participation",
        "The Peer Learning Handbook by Boud et al. (Introduction, ~10 pages) — practical orientation to peer methods"
      ],
      "discussion_prompts": [
        "When have you learned something important from a peer rather than a teacher? What made it stick?",
        "What assumptions about teaching and learning did you arrive with today?",
        "What would need to be true for a group without an instructor to learn something difficult?"
      ],
      "inquiry_activity": "Each member shares one example of learning from a peer. Group maps common themes on a shared whiteboard and names two patterns they want to test across the six weeks."
    },
    {
      "week_number": 2,
      "guiding_question": "How does an inquiry framework change the way a group talks about a topic?",
      "resources": [
        "The Art of Powerful Questions by Vogt, Brown, and Isaacs (full paper, ~10 pages) — applies directly to peer facilitation",
        "Thinking Together by William Isaacs (Chapter 4, ~15 pages) — dialogue vs. debate as a distinction the ring can use"
      ],
      "discussion_prompts": [
        "What is the difference between a question that opens and a question that closes?",
        "Pick one question from last week. How would you reframe it using the Three Lenses?",
        "What would it look like to apply this framework to a topic you find genuinely difficult?"
      ],
      "inquiry_activity": "Practice session: one member brings a real topic question; the rest use the Three Lenses framework to generate follow-on questions. Debrief on what the framework made visible that wasn't there before."
    },
    {
      "week_number": 3,
      "guiding_question": "What are the conditions that make peer learning break down, and what does that reveal about how it works?",
      "resources": [
        "Collaborative Learning Techniques by Barkley et al. (Chapter 2, ~20 pages) — identifies common failure modes",
        "The Wisdom of Crowds by Surowiecki (Chapter 10, ~15 pages) — when groups get worse at thinking, not better"
      ],
      "discussion_prompts": [
        "Recall a group learning experience that failed. What was the structural cause?",
        "Which failure mode from the reading most resembles a risk in this ring?",
        "What would you add to the Three Lenses framework to address one of those failure modes?"
      ],
      "inquiry_activity": "Ring audit: each member scores the ring itself on three dimensions (safety, rigor, engagement) on a 1–5 scale, anonymously. Share aggregated scores and discuss what they reveal."
    },
    {
      "week_number": 4,
      "guiding_question": "What does someone who has run peer learning programs in practice know that the literature doesn't say?",
      "resources": [
        "Cultivating Communities of Practice by Wenger, McDermott, and Snyder (Chapter 3, ~20 pages) — practitioner-oriented; bridges theory and implementation",
        "Prepared by the ring based on questions for the guest: 5 questions, submitted 48 hours before the session"
      ],
      "discussion_prompts": [
        "What did the guest say that contradicted something you read in Weeks 1–3?",
        "What question did you not ask but wish you had?",
        "How would you revise the Three Lenses framework based on what the guest shared?"
      ],
      "inquiry_activity": "Guest conversation (45 minutes). Remaining 15 minutes: ring members capture three things they want to carry into the Week 6 artifact from today's conversation."
    },
    {
      "week_number": 5,
      "guiding_question": "What does a peer learning ring that failed teach us about what makes one succeed?",
      "resources": [
        "Failure Cases in Collaborative Learning (ring-curated collection) — at least two examples the ring sourced itself",
        "Guest's own account of a failed ring or study group (requested in advance)"
      ],
      "discussion_prompts": [
        "What is the single most important structural condition for a peer learning ring to succeed?",
        "If you were designing a ring for a topic you care about, what would you change from what we did here?",
        "What would the artifact need to say for it to be genuinely useful to someone who wasn't in this ring?"
      ],
      "inquiry_activity": "Draft artifact outline: ring agrees on a shared structure for the Week 6 synthesis document. Each member takes one section to draft before the final session."
    },
    {
      "week_number": 6,
      "guiding_question": "What did we actually learn, and how will we share it?",
      "resources": [
        "Drafts produced by each member in Week 5 (ring's own material)",
        "Week 1 assumptions list (retrieved from whiteboard or notes) — used to measure shift"
      ],
      "discussion_prompts": [
        "What changed in how you understand peer learning from Week 1 to Week 6?",
        "What is the one thing you would tell someone starting a ring tomorrow?",
        "What question is still open for you — the one this ring didn't resolve?"
      ],
      "inquiry_activity": "Synthesis session: ring assembles the final document collaboratively, reconciles member drafts, and agrees on the one open question to name at the end. Final version shared with all members before the session ends."
    }
  ]
}
```

### 5.3 — Implement `RingsController#generate`

Replace the stub with the full implementation:

```ruby
def generate
  @ring.update!(status: "generating")

  response = GeminiService.generate(
    template:  "studyrings_curriculum_v1",
    variables: {
      topic:              @ring.topic,
      member_background:  @ring.member_background,
      meeting_frequency:  @ring.meeting_frequency,
      purpose:            @ring.purpose
    }
  )

  data = JSON.parse(response, symbolize_names: true)

  sessions = data[:sessions]
  raise GeminiService::GeminiError, "Expected 6 sessions, got #{sessions&.length || 0}" if sessions&.length != 6

  ActiveRecord::Base.transaction do
    charter = @ring.create_learning_charter!(
      gemini_raw:          response,
      focus_statement:     data[:focus_statement],
      learning_goals:      Array(data[:learning_goals]).join("\n"),
      success_indicators:  Array(data[:success_indicators]).join("\n"),
      inquiry_framework:   data[:inquiry_framework],
      invite_suggestions:  data[:invite_suggestions],
      artifact_template:   data[:artifact_template]
    )

    sessions.each do |s|
      charter.ring_sessions.create!(
        week_number:       s[:week_number],
        guiding_question:  s[:guiding_question],
        resources:         Array(s[:resources]).join("\n"),
        discussion_prompts: Array(s[:discussion_prompts]).join("\n"),
        inquiry_activity:  s[:inquiry_activity]
      )
    end
  end

  @ring.update!(status: "complete")
  redirect_to ring_path(@ring), notice: "Your curriculum is ready."

rescue JSON::ParserError
  @ring.update!(status: "failed")
  render "rings/show", status: :unprocessable_entity

rescue GeminiService::BudgetExceededError
  @ring.update!(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }, status: :unprocessable_entity

rescue GeminiService::GatekeeperError
  @ring.update!(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }, status: :unprocessable_entity

rescue GeminiService::TimeoutError
  @ring.update!(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :timeout }, status: :unprocessable_entity

rescue GeminiService::GeminiError
  @ring.update!(status: "failed")
  render partial: "shared/ai_error", locals: { error_type: :error }, status: :unprocessable_entity
end
```

### 5.4 — Verify the admin template panel

After seeding, sign in as admin and verify the template can be tested through the browser:
- `GET /admin/ai_templates` — `studyrings_curriculum_v1` appears in the list
- Click Edit → the test panel shows the four variable inputs (`topic`, `member_background`, `meeting_frequency`, `purpose`)
- Fill in sample values and click `Run Test` — the response renders inline

---

## Manual Tests

1. Sign in, go to `/rings`, click into the draft ring seeded in Phase 8 (or create a new one)
2. Click `Generate curriculum` — observe redirect; status should flip to `complete`
3. Show page now shows "Charter ready — coming in Phase 6" placeholder
4. Check `/admin/llm_requests` — new row with `success` status and `studyrings_curriculum_v1` template name
5. In console: `Ring.last.learning_charter` — present, `focus_statement` populated
6. In console: `Ring.last.ring_sessions.count` — returns `6`
7. In console: `Ring.last.ring_sessions.pluck(:week_number).sort` — returns `[1, 2, 3, 4, 5, 6]`
8. Test failure path: temporarily blank out `GEMINI_API_KEY` in `.env`, restart server, try to generate — should render error partial with Retry button, ring status = `failed`
9. Test budget exceeded: in console, set `ENV["AI_CALLS_PER_USER_PER_DAY"] = "0"` (or use `stub_const`) — budget exceeded error renders
10. Verify `/admin/ai_templates/studyrings_curriculum_v1/edit` — test panel variables auto-populate

---

## RSpec Tests

Add to `spec/requests/rings_spec.rb`. Use the fixture file to stub Gemini:

```ruby
let(:fixture_response) do
  File.read(Rails.root.join("spec/fixtures/studyrings_curriculum_response.json"))
end

describe "POST /rings/:id/generate" do
  before { sign_in_as(user) }

  context "with a successful Gemini response" do
    before { gemini_returns(fixture_response) }

    it "calls GeminiService with the correct template and variables" do
      expect(GeminiService).to receive(:generate).with(
        hash_including(template: "studyrings_curriculum_v1",
                       variables: hash_including(:topic, :member_background,
                                                 :meeting_frequency, :purpose))
      ).and_return(fixture_response)
      post generate_ring_path(ring)
    end

    it "creates one LearningCharter" do
      expect { post generate_ring_path(ring) }.to change(LearningCharter, :count).by(1)
    end

    it "creates six RingSessions" do
      expect { post generate_ring_path(ring) }.to change(RingSession, :count).by(6)
    end

    it "sets ring status to complete" do
      post generate_ring_path(ring)
      expect(ring.reload.status).to eq("complete")
    end

    it "redirects to the ring show page" do
      post generate_ring_path(ring)
      expect(response).to redirect_to(ring_path(ring))
    end
  end

  context "on GeminiService::TimeoutError" do
    before { gemini_raises(GeminiService::TimeoutError) }

    it "sets ring status to failed" do
      post generate_ring_path(ring)
      expect(ring.reload.status).to eq("failed")
    end

    it "renders a timeout message" do
      post generate_ring_path(ring)
      expect(response.body).to match(/timeout|timed out/i)
    end
  end

  context "on GeminiService::BudgetExceededError" do
    before { gemini_raises(GeminiService::BudgetExceededError) }

    it "sets ring status to failed" do
      post generate_ring_path(ring)
      expect(ring.reload.status).to eq("failed")
    end

    it "renders a budget exceeded message" do
      post generate_ring_path(ring)
      expect(response.body).to match(/budget|daily limit/i)
    end
  end

  context "on JSON::ParserError (malformed response)" do
    before { allow(GeminiService).to receive(:generate).and_return("not valid json {{{{") }

    it "sets ring status to failed" do
      post generate_ring_path(ring)
      expect(ring.reload.status).to eq("failed")
    end
  end

  context "when ring belongs to another user" do
    let(:other_ring) { create(:ring, user: other_user) }

    it "returns 404" do
      post generate_ring_path(other_ring)
      expect(response).to have_http_status(:not_found)
    end
  end
end
```

Run:

```bash
bundle exec rspec spec/requests/rings_spec.rb
```

---

## Acceptance Criteria

- [ ] `db/seeds.rb` seeds `studyrings_curriculum_v1` with the full system prompt, user prompt template, `gemini-2.5-flash`, `max_output_tokens: 3000`, `temperature: 0.6`
- [ ] `bin/rails db:seed` is idempotent (runs twice without errors or duplicate records)
- [ ] `spec/fixtures/studyrings_curriculum_response.json` is valid JSON with exactly 6 sessions
- [ ] `generate` action creates one `LearningCharter` and exactly 6 `RingSession` records on success
- [ ] `ring.status` transitions: `draft` → `generating` → `complete` on success
- [ ] `ring.status` = `failed` on all error paths (timeout, budget, gatekeeper, JSON parse)
- [ ] The correct `GeminiService` error subclass renders the correct error partial messaging
- [ ] All RSpec cases pass with no real API calls
