# StudyRings Demo - Product Spec

**Document Version:** 1.0
**Last Updated:** May 4, 2026
**Built On:** Open Demo Starter v2.0 (boilerplate)
**Tagline:** Pick a topic. Get a 6-week peer learning curriculum your ring can run itself.
**License:** MIT

---

## 1. App Overview

StudyRings Demo is a single-feature, open source Rails 8 application that turns a topic, a member background level, a meeting cadence, and a one-sentence purpose into a complete peer learning curriculum. The output is an O.R.B.I.T. learning charter (Origin, Rhythm, Build, Invite, Transform) and a six-session week-by-week plan that a small peer group can run on its own with no instructor.

The problem this solves is narrow and specific: people who want to learn together as peers usually stall after three meetings because nobody owns the structure. Course generators are built for instructors and produce lessons to be taught. StudyRings inverts that. It produces questions to explore together, with a six-week arc designed to deepen along Bloom's Taxonomy, ending in an artifact the ring builds rather than a test the ring takes.

This demo is one tool from a larger multi-tenant SaaS product the author is building. The production version supports multiple organizations, ring memberships, ongoing session tracking, resource collections, discussion threads, learning artifacts, and ring health analytics across teams. This demo deliberately does none of that. It isolates the single highest-value moment in the production app, the curriculum generation, and ships it as a clean local Rails app a visitor can clone, run, and read in under thirty minutes.

This demo is open source under MIT license, scoped to a single signed-in user, runs only on localhost, and uses the Open Demo Starter v2.0 boilerplate as its entire foundation for authentication, layout, AI service, request logging, gatekeeper, budget cap, admin panel, and test setup.

---

## 2. Customizations Applied to the Boilerplate

Everything in this section is a place this app diverges from the default boilerplate. Anything not listed here is unchanged from Open Demo Starter v2.0.

| Customization Point | Value |
|---|---|
| `APP_NAME` (in `.env.example`) | `StudyRings Demo` |
| `APP_TAGLINE` | `Pick a topic. Get a 6-week peer learning curriculum your ring can run itself.` |
| `APP_DESCRIPTION` | `An open source demo that generates a complete O.R.B.I.T. learning charter and 6-session curriculum for a peer learning ring, from a single topic prompt.` |
| Accent color (in `_accent.scss`) | `--accent: #b45309;` (rich brown) and `--accent-hover: #92400e;` (deeper brown) |
| Secondary accent | `--accent-secondary: #f87171;` (warm coral) used for current-phase ring markers and active state badges |
| Navbar primary link | `Rings` linking to `/rings` |
| Navbar primary action | `New Ring` button linking to `/rings/new`, styled `.btn-accent` |
| Home page (`home/index.html.erb`) | Replaced with a one-screen pitch: hero text, three-column "What is a Ring", a static example charter snippet, and a "Sign up to create your first Ring" CTA |
| Dashboard page (`dashboard/show.html.erb`) | Replaced with the rings index view (described in Section 6) |
| UX pattern | Concentric ring SVG cards on the index page (each card's marker shows current week as filled rings out of six); horizontal week-by-week timeline on the show page; right sidebar showing the artifact template the ring is building toward |
| Footer addition | Adds a small line under the inherited AI disclaimer: `Curricula are AI-generated starting points, not pedagogical advice. Adapt before using with your ring.` |
| AI templates seeded in `db/seeds.rb` | `studyrings_curriculum_v1` (full content in Section 7) |

No other boilerplate files are modified. The auth flow, admin panel, AI service, gatekeeper, budget checker, request log, and test setup are inherited unchanged.

---

## 3. Data Model

Three new domain models on top of the boilerplate's `User`, `AiTemplate`, and `LlmRequest`. All scoped to `current_user`.

### Ring

The user-created object. Holds the inputs the user provides; the AI fills in the rest as a `LearningCharter` and six `RingSession` records.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | `belongs_to :user` |
| `topic` | string | **(template variable)** The learning topic, e.g., "Practical applications of network theory in community organizing" |
| `member_background` | string | **(template variable)** Enum-like: `beginner`, `mixed`, `experienced` |
| `meeting_frequency` | string | **(template variable)** Enum-like: `weekly`, `biweekly` |
| `purpose` | text | **(template variable)** A single sentence on why this ring exists |
| `status` | string | `draft`, `generating`, `complete`, `failed`. Default `draft` |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :user`
- `has_one :learning_charter, dependent: :destroy`
- `has_many :ring_sessions, through: :learning_charter`

**Validations:**
- `topic` presence, length 5 to 200
- `member_background` inclusion in `%w[beginner mixed experienced]`
- `meeting_frequency` inclusion in `%w[weekly biweekly]`
- `purpose` presence, length 10 to 500
- `status` inclusion in `%w[draft generating complete failed]`

### LearningCharter

The structured AI output for a Ring. One per Ring. Created when the user clicks "Generate curriculum".

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `ring_id` | uuid | `belongs_to :ring` |
| `focus_statement` | text | One paragraph naming what this ring is studying |
| `learning_goals` | text | Three goals stated as outcomes (newline-delimited) |
| `success_indicators` | text | How the ring will know it has progressed |
| `inquiry_framework` | text | A topic-specific framework the ring can use in any session |
| `invite_suggestions` | text | Suggested guest perspectives or external voices for weeks 4 to 5 |
| `artifact_template` | text | Description of the artifact the ring will produce by week 6 |
| `gemini_raw` | text | **(Gemini output, used for Show raw response toggle)** The complete unparsed response |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :ring`
- `has_many :ring_sessions, dependent: :destroy`

**Validations:**
- `ring_id` presence and uniqueness
- `gemini_raw` presence

### RingSession

One row per week, six per Ring. Created in the same transaction that creates the `LearningCharter`.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `learning_charter_id` | uuid | `belongs_to :learning_charter` |
| `week_number` | integer | 1 through 6 |
| `guiding_question` | text | The single question the session orbits around |
| `resources` | text | Two reading or resource suggestions (newline-delimited) |
| `discussion_prompts` | text | Three discussion prompts (newline-delimited) |
| `inquiry_activity` | text | One collaborative inquiry activity description |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :learning_charter`
- `has_one :ring, through: :learning_charter`

**Validations:**
- `week_number` presence, inclusion in 1 through 6
- Uniqueness of `week_number` scoped to `learning_charter_id`
- `guiding_question` presence

---

## 4. Routes

All HTML responses. RESTful conventions. No JSON API.

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/` | `home#index` | Public landing page (overridden) |
| GET | `/dashboard` | `rings#index` | Logged-in home (rings list, replaces dashboard) |
| GET | `/rings` | `rings#index` | List of the user's rings |
| GET | `/rings/new` | `rings#new` | Form for new ring inputs |
| POST | `/rings` | `rings#create` | Create the Ring record (status `draft`) |
| GET | `/rings/:id` | `rings#show` | Ring detail page; if charter exists, render it |
| DELETE | `/rings/:id` | `rings#destroy` | Delete the ring and its charter and sessions |
| POST | `/rings/:id/generate` | `rings#generate` | Triggers the Gemini call and creates `LearningCharter` plus 6 `RingSession` records |

Auth routes (`/sign_up`, `/sign_in`, `/sign_out`, `/passwords/*`), admin routes (`/admin/*`), and health routes (`/up`, `/up/llm`) come from the boilerplate and are not redescribed here.

---

## 5. Controllers and Actions

One new controller. All actions inherit `before_action :require_authentication` and scope every query to `current_user`.

### `RingsController`

- `index` lists `current_user.rings` ordered by `created_at DESC`. Used as both `/rings` and `/dashboard`.
- `new` renders an empty `Ring` for the form.
- `create` saves the Ring with `status: "draft"`, then redirects to the show page where the user can click "Generate curriculum".
- `show` loads the ring, eager-loads `learning_charter` and `ring_sessions`, and renders the appropriate state (draft prompt, generating spinner, complete charter, or failed retry).
- `destroy` destroys the Ring; cascading destroys remove the charter and sessions.
- `generate` is the action that triggers the Gemini call. It does the following:
  1. Updates `ring.status` to `generating`.
  2. Calls `GeminiService.generate(template: "studyrings_curriculum_v1", variables: { topic:, member_background:, meeting_frequency:, purpose: })`.
  3. Parses the JSON response.
  4. In a single transaction, creates the `LearningCharter` (with `gemini_raw` set to the raw response) and six `RingSession` records.
  5. Updates `ring.status` to `complete` on success.
  6. On `GeminiService::GeminiError`, sets `ring.status` to `failed` and renders the boilerplate's friendly inline alert partial with a retry button. Subclasses (`BudgetExceededError`, `GatekeeperError`, `TimeoutError`) get specific messaging. The `LlmRequest` record already captured the failure for admin inspection.

Strong parameters allow only `topic`, `member_background`, `meeting_frequency`, and `purpose` on Ring.

The boilerplate's `ApplicationController`, `Admin::*`, `SessionsController`, `RegistrationsController`, `PasswordsController`, and `HealthController` are inherited unchanged.

---

## 6. Views

Every new view file added on top of the boilerplate. Layout overrides only where listed. All Gemini-rendered output includes the boilerplate's "Show raw response" Bootstrap collapse pointing at `learning_charter.gemini_raw`.

### `home/index.html.erb` (override)

Replaces the boilerplate placeholder. Hero section with the tagline. Three-column "How a Ring works" callout. A static example charter card. A primary `Sign up` CTA linking to `/sign_up`.

### `rings/index.html.erb` (also rendered by `dashboard#show`)

Card grid of the user's rings. Each card uses the **concentric ring SVG marker** as its left-side glyph: six rings arranged concentrically, with the current `week_number` reached filled in `var(--accent-secondary)` (warm coral) and the rest in muted brown outlines. For drafts (no charter yet) all rings are outlined and a `var(--accent-secondary)` "Not started" badge appears top-right. The card also shows the topic, the member background label, and a `Created N days ago` line. The full card is a link to the show page. A single `New Ring` button at the top right of the grid.

Empty state shows the example from `home/index.html.erb` framed as "Your first ring is one click away" with the same CTA targeting `/rings/new`.

### `rings/new.html.erb`

A single-column form with four inputs: `topic` (text input), `member_background` (radio group: Beginner, Mixed, Experienced), `meeting_frequency` (radio group: Weekly, Biweekly), `purpose` (textarea, two-line height, with helper text "One sentence. Why does this ring exist?"). Submit button reads `Create ring`. On success the user lands on the show page where they confirm and click `Generate curriculum`.

### `rings/show.html.erb`

The primary view. Three states:

- **Draft state.** Shows the four inputs back to the user and a single primary `Generate curriculum` button that POSTs to `/rings/:id/generate`. A short note above the button says `This will use 1 of your 50 daily AI calls.` (The number is sourced from `ENV["AI_CALLS_PER_USER_PER_DAY"]`.)

- **Generating state.** Renders inside a `<turbo-frame id="ring-curriculum">`. A centered spinner and the line `Drafting your charter and six sessions. This usually takes 8 to 15 seconds.` The frame source polls `/rings/:id` every 3 seconds via a Stimulus controller `data-controller="ring-poller"` until status flips.

- **Complete state.** Renders the charter at the top in a Bootstrap `card` with the focus statement, learning goals (as an unordered list), success indicators (as an unordered list), and the inquiry framework. Below that, a horizontal **week-by-week timeline** of six `RingSession` cards laid out as a flex row that scrolls horizontally on narrow screens. Each session card shows `Week N`, the guiding question (large text), the two resources, the three discussion prompts, and the inquiry activity. The right sidebar (Bootstrap `col-lg-3`) renders the `artifact_template` text inside a sticky-positioned `card` with a header reading `What this ring is building` and a small concentric-ring icon. A "Show raw response" toggle below the timeline reveals the full `gemini_raw` text in a Bootstrap `collapse`. A `Delete ring` button (with confirm) appears in the page header next to a `Print` link that triggers `window.print()`.

- **Failed state.** Renders the inherited fail-soft alert partial (`shared/_ai_error.html.erb` from the boilerplate) with a `Retry` button that re-POSTs to `/rings/:id/generate`. The specific subclass message is shown.

### `rings/_concentric_ring_marker.html.erb` (partial)

Inline SVG. Six concentric circle rings, no animation. Accepts `current_week` (0 through 6); paints filled circles for completed weeks and outlines for future weeks. Used in the index card and the right sidebar header. Stroke width is 1.5; size is 48 by 48 pixels by default with a `size:` local variable for variation.

### `rings/_session_card.html.erb` (partial)

Renders a single `RingSession`. Used inside the timeline.

---

## 7. AI Templates and Gemini Integration

This demo seeds exactly one `AiTemplate`. It is the engine of the app.

### Template: `studyrings_curriculum_v1`

| Field | Value |
|---|---|
| `name` | `studyrings_curriculum_v1` |
| `description` | Generates a complete O.R.B.I.T. learning charter and 6-session curriculum for a peer learning ring, structured to climb Bloom's Taxonomy from Week 1 to Week 6. |
| `model` | `gemini-2.0-flash` |
| `max_output_tokens` | `3000` (raised from boilerplate default of 2000 because the structured output is long: charter plus six sessions with multiple fields each) |
| `temperature` | `0.6` (lower than the 0.7 default; the structure must be predictable enough to parse as JSON, but the inquiry questions still benefit from some variation) |

#### `system_prompt`

```
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
```

#### `user_prompt_template`

```
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
  "artifact_template": "<a description of one artifact the ring will produce by week 6: a synthesis document, a teaching framework, a presentation outline, or a follow-up ring proposal. Pick the one best suited to this topic.>",
  "sessions": [
    {
      "week_number": 1,
      "guiding_question": "<one question that orbits the week's Bloom level>",
      "resources": [
        "<resource 1: title, format, and one-line rationale>",
        "<resource 2: title, format, and one-line rationale>"
      ],
      "discussion_prompts": [
        "<prompt 1>",
        "<prompt 2>",
        "<prompt 3>"
      ],
      "inquiry_activity": "<one collaborative activity description>"
    },
    { "week_number": 2, ... same shape ... },
    { "week_number": 3, ... same shape ... },
    { "week_number": 4, ... same shape ... },
    { "week_number": 5, ... same shape ... },
    { "week_number": 6, ... same shape ... }
  ]
}

The "sessions" array must contain exactly 6 objects, in week_number order from 1 to 6.
```

#### Variables consumed

- `{{topic}}` from `Ring#topic`
- `{{member_background}}` from `Ring#member_background`
- `{{meeting_frequency}}` from `Ring#meeting_frequency`
- `{{purpose}}` from `Ring#purpose`

#### Author's notes (`notes` field)

```
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
```

#### Where it's called

`RingsController#generate`. Single call per Ring per generate action. The user can re-trigger after a failure but each retry counts against the daily call cap.

#### Expected output format

JSON, parsed with `JSON.parse(response, symbolize_names: true)`. The schema is the one shown in `user_prompt_template`. The full unparsed response is stored on `LearningCharter#gemini_raw`.

#### How the response is parsed and rendered

The controller parses the JSON, then in a single ActiveRecord transaction creates one `LearningCharter` (mapping `focus_statement`, `inquiry_framework`, `invite_suggestions`, `artifact_template`, and `gemini_raw` directly; joining `learning_goals` and `success_indicators` arrays with newlines for storage as text fields) and six `RingSession` records (mapping `guiding_question`, joining `resources` and `discussion_prompts` arrays with newlines, and storing `inquiry_activity` as plain text). If the array length is not 6 or any required field is missing, the transaction rolls back and the error is surfaced via the fail-soft UI.

Newlines are used as the in-text delimiter rather than introducing extra tables for resources and prompts. The view splits on newlines when rendering as lists. This keeps the model count to three.

---

## 8. AI Safety Considerations (Specific to This App)

StudyRings Demo is **low-stakes**. The output is a peer learning curriculum. The worst case from a user acting on bad output is that a study group has a less productive first session, not that anyone is harmed.

### Content sensitivity

Topics can be politically charged (current events), professionally sensitive (workplace dynamics), or personally meaningful (grief, addiction, faith). The system prompt does not steer the model toward "safe" topics; the gatekeeper's existing prompt-injection check is sufficient. Users entering topics about regulated domains (legal advice, medical advice, mental health treatment) will get curricula that read like peer learning curricula about those topics, not professional guidance. The footer disclaimer plus the additional StudyRings note in the footer make this explicit.

### Domain accuracy

The model fabricates resource recommendations. Specific book titles, article URLs, and author attributions returned in the `resources` field may not exist. The view prefixes the resources block with the line: `Suggested starting points. The ring chooses what to actually read.` This reframes the field as inspiration, not a curated reading list, which is more honest about the model's reliability and also matches how a real ring works.

### App-specific disclaimer

In addition to the boilerplate's `AI-generated content can be incorrect. Verify before acting.` footer note, this app adds: `Curricula are AI-generated starting points, not pedagogical advice. Adapt before using with your ring.` This appears in the footer and also as a small italicized line at the bottom of every generated charter.

### Tightened settings

- `max_output_tokens` is raised to 3000 from the default 2000, not lowered. The structured output requires the higher cap. If the cap is reached mid-output, the JSON parse will fail and the user gets a friendly retry. This is a deliberate tradeoff: oversized output cost is acceptable for a demo; clipped output is not.
- `temperature` is lowered to 0.6 from the default 0.7 for parse reliability.
- The per-user daily call cap remains at the boilerplate default of 50 calls per day. A user generating fifty rings in one day is either testing the demo or abusing it; either way the cap is right.
- The gatekeeper's input length limit (5000 chars from the boilerplate) is not changed. The combined input from the four Ring fields will not approach this limit in normal use.

### What this demo deliberately does NOT do

- No content moderation API call before generation. The gatekeeper's basic profanity check is sufficient for a single-user local demo.
- No PII scrubbing on the `purpose` field. Users may put names of people in the purpose ("for my team's onboarding"); the README warns not to put real personal data in the demo.
- No fact-checking of resources. The output explicitly frames resources as starting points, not citations.
- No safety classifier on the topic. A user typing a harmful topic gets back a peer learning curriculum about that topic, which is both unsurprising and not a meaningful uplift compared to a generic web search.
- No tracking of which sessions a ring actually ran or how the curriculum performed in practice. That is the production app's territory and out of scope for the demo.

This section's brevity is the point: the boilerplate covers the operational concerns; the app-specific risk surface is small; the deliberate omissions are listed with rationale.

---

## 9. RSpec Outline

New spec files only. Boilerplate specs (`user_spec.rb`, `ai_template_spec.rb`, `llm_request_spec.rb`, `gemini_service_spec.rb`, `ai_gatekeeper_spec.rb`, `ai_budget_checker_spec.rb`, auth specs, admin specs) are inherited and not redescribed.

### `spec/models/ring_spec.rb`

- Validates `topic`, `member_background`, `meeting_frequency`, `purpose`, `status` presence and inclusion
- `belongs_to :user`
- `has_one :learning_charter, dependent: :destroy`
- Destroying a Ring destroys its charter and the six sessions

### `spec/models/learning_charter_spec.rb`

- Validates `ring_id` uniqueness and `gemini_raw` presence
- `has_many :ring_sessions` with `dependent: :destroy`
- Splits `learning_goals` on newlines into an array via a helper method

### `spec/models/ring_session_spec.rb`

- Validates `week_number` inclusion in 1 through 6
- Validates `week_number` uniqueness scoped to `learning_charter_id`
- Validates `guiding_question` presence
- Splits `resources` and `discussion_prompts` on newlines into arrays via helper methods

### `spec/requests/rings_spec.rb`

- Unauthenticated user is redirected to sign in for every action
- `POST /rings` with valid params creates a Ring with `status: "draft"`
- `POST /rings` with invalid params re-renders the form with errors
- `POST /rings/:id/generate` calls `GeminiService.generate` with template `studyrings_curriculum_v1` and the four expected variables (verified via the boilerplate's stubbed Gemini test double returning a fixture JSON)
- `POST /rings/:id/generate` creates one `LearningCharter` and six `RingSession` records on success
- `POST /rings/:id/generate` creates an `LlmRequest` record on success (verified via the boilerplate's existing log assertions)
- `POST /rings/:id/generate` on `GeminiService::TimeoutError` sets `ring.status` to `failed` and renders the retry partial
- `POST /rings/:id/generate` on `GeminiService::BudgetExceededError` shows the budget-exceeded message
- A different signed-in user accessing another user's ring `show`, `destroy`, or `generate` gets a 404
- `DELETE /rings/:id` destroys the ring and its charter and sessions

### `spec/fixtures/studyrings_curriculum_response.json`

Sample valid JSON response used to stub `GeminiService.generate`. Mirrors the schema in Section 7. Loaded in request specs.

---

## 10. Seed Data

`db/seeds.rb` extends the boilerplate's seeded admin demo user (`demo@example.com` / `password123`, `admin: true`).

### AI template seed

Creates one `AiTemplate` record with `name: "studyrings_curriculum_v1"`, the full `system_prompt` and `user_prompt_template` from Section 7, `model: "gemini-2.0-flash"`, `max_output_tokens: 3000`, `temperature: 0.6`, and the author's notes from Section 7.

### Domain seeds

Creates one realistic example `Ring` for the demo user so that the rings index has something to look at on first run:

- `topic`: `Network theory and how communities actually organize`
- `member_background`: `mixed`
- `meeting_frequency`: `biweekly`
- `purpose`: `Three of us keep arguing about whether 'community' has any concrete meaning, and we want to read together until we have a useful answer.`
- `status`: `draft`

The seed does NOT pre-generate the curriculum, so a fresh setup leaves one ring in draft state ready for the visitor to click `Generate curriculum` and see the AI flow. This makes the first-run experience demonstrate the value of the app within thirty seconds.

---

## 11. README Additions

### App-specific sections

```
# StudyRings Demo

Pick a topic. Get a 6-week peer learning curriculum your ring can run itself.

[screenshot placeholder: rings index showing concentric ring cards plus a generated charter on the show page]

## What this is

A single-feature open source Rails 8 demo. You enter a topic, a member background
level, a meeting frequency, and a one-sentence purpose. Gemini returns a complete
O.R.B.I.T. learning charter (Origin, Rhythm, Build, Invite, Transform) and a
6-session curriculum that climbs Bloom's Taxonomy from Remember at Week 1 to
Create at Week 6.

## Why I built this

This is one feature from a larger multi-tenant SaaS product I'm building called
StudyRings, where small peer groups form around a shared curiosity, build a
growing collection of learning materials together, and produce lasting artifacts
of what they learned. The production app handles ongoing rings, sessions,
resources, discussions, and ring health. This demo isolates the single moment
that makes the rest of it work: the curriculum generation.

The full StudyRings product landing page is at https://studyrings.com (placeholder).
This demo is open source under MIT license. Clone it, edit it, ship your own.

## The AI prompt is editable

Sign in as demo@example.com / password123 (admin), open /admin/ai_templates,
click `studyrings_curriculum_v1`, and edit the system prompt or user prompt
template directly in the browser. The test panel on the right side runs the
draft against Gemini without saving. When you have something better than what
the seed file shipped with, save it; the next "Generate curriculum" click uses
your version.

## Setup

```bash
bin/setup
cp .env.example .env
# Add your Gemini API key to .env
bin/rails server
```

The standard sections (Stack, License, AI Safety Posture, About the Author) are inherited from the boilerplate's README template and are not rewritten here.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### UX pattern this app uses

Card grid on the index page; form-then-result on the new and show pages; horizontal week-by-week timeline as the dominant element on the show page; right sidebar reminder of the artifact the ring is building toward. No tabs, no kanban, no wizard.

### How `var(--accent)` is applied

- All primary buttons (`Create ring`, `Generate curriculum`, `Retry`) use `.btn-accent`, a custom Bootstrap variant defined in `_accent.scss` that maps `background-color` to `var(--accent)` and hover to `var(--accent-hover)`.
- Active nav link uses `border-bottom: 2px solid var(--accent)`.
- Links inside generated content (`a` tags within charter and session cards) use `color: var(--accent)`.
- The concentric-ring SVG marker uses `var(--accent)` as the stroke color for outline rings and `var(--accent-secondary)` (the warm coral) as the fill for the active week marker.
- Bootstrap `.badge` instances for the ring status use `--accent-secondary` for `Not started` and `--accent` for `Generating` and `Complete`.

### Custom CSS added

Kept minimal:

- `.btn-accent` variant (background, hover, focus ring)
- `.ring-marker svg` sizing helpers (`size-sm`, `size-md`, `size-lg`)
- `.session-timeline` flex container with `overflow-x: auto` and `scroll-snap-type: x mandatory` for the horizontal session timeline
- `.artifact-sidebar` sticky position, `top: 1rem`

Everything else uses Bootstrap 5 utilities directly. No additional stylesheet bundlers; `_accent.scss` is the only file modified beyond the boilerplate's defaults.

---

*v1.0 - StudyRings Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
