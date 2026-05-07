# Phase 6 — Complete State View and Partials

**Goal:** Build the full charter display on the ring show page: O.R.B.I.T. charter card, horizontal week-by-week session timeline, right sidebar with artifact template, raw response toggle, and AI disclaimer.

**Depends on:** Phase 5 complete. At least one ring with `status: "complete"` and a generated `LearningCharter` + 6 `RingSession` records must exist.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Section 6

---

## Context

This phase adds two new partials and rewrites the complete-state block inside `rings/show.html.erb`. The draft, generating, and failed states from Phase 4 are not changed.

**Critical:** `learning_goals` and `success_indicators` are stored as newline-delimited text. Always call the model helper methods (`learning_goals_list`, `success_indicators_list`, `resources_list`, `discussion_prompts_list`) — never split manually in the view.

**Resources caveat:** The view must prefix the resources block with `Suggested starting points. The ring chooses what to actually read.` This reframes the output as inspiration, not a curated reading list.

**The right sidebar** uses `.artifact-sidebar` (position: sticky, top: 1rem) from Phase 1's CSS. It uses Bootstrap's `col-lg-3` in a `row` alongside the main `col-lg-9`.

---

## Tasks

### 6.1 — Create `app/views/rings/_session_card.html.erb`

Accepts one local: `session` (a `RingSession` instance).

```erb
<%# locals: (session:) %>
<div class="card session-card h-100">
  <div class="card-header">
    <strong>Week <%= session.week_number %></strong>
  </div>
  <div class="card-body d-flex flex-column">
    <p class="fs-5 fw-semibold"><%= session.guiding_question %></p>

    <h6 class="mt-3 text-muted">Resources</h6>
    <p class="text-muted small fst-italic">Suggested starting points. The ring chooses what to actually read.</p>
    <ul class="small">
      <% session.resources_list.each do |resource| %>
        <li><%= resource %></li>
      <% end %>
    </ul>

    <h6 class="mt-3 text-muted">Discussion Prompts</h6>
    <ol class="small">
      <% session.discussion_prompts_list.each do |prompt| %>
        <li><%= prompt %></li>
      <% end %>
    </ol>

    <h6 class="mt-3 text-muted">Inquiry Activity</h6>
    <p class="small fst-italic mt-auto"><%= session.inquiry_activity %></p>
  </div>
</div>
```

### 6.2 — Update `app/views/rings/show.html.erb` — complete state block

Replace the `<p>Charter ready — coming in Phase 6.</p>` placeholder with the full layout:

```erb
<%# Complete state — shown when @ring.status == "complete" %>
<% if @ring.status == "complete" && @charter %>

  <div class="row">
    <%# Main column — charter card + timeline %>
    <div class="col-lg-9">

      <%# O.R.B.I.T. charter card %>
      <div class="card mb-4">
        <div class="card-header">
          <strong>Learning Charter</strong>
        </div>
        <div class="card-body">
          <p><%= @charter.focus_statement %></p>

          <h6 class="mt-3">Learning Goals</h6>
          <ul>
            <% @charter.learning_goals_list.each do |goal| %>
              <li><%= goal %></li>
            <% end %>
          </ul>

          <h6 class="mt-3">Success Indicators</h6>
          <ul>
            <% @charter.success_indicators_list.each do |indicator| %>
              <li><%= indicator %></li>
            <% end %>
          </ul>

          <h6 class="mt-3">Inquiry Framework</h6>
          <p><%= @charter.inquiry_framework %></p>
        </div>
      </div>

      <%# Week-by-week session timeline %>
      <h5 class="mb-3">Six-Session Plan</h5>
      <div class="session-timeline mb-4">
        <% @sessions.each do |session| %>
          <%= render "rings/session_card", session: session %>
        <% end %>
      </div>

      <%# Raw response toggle %>
      <div class="mb-4">
        <a class="btn btn-outline-secondary btn-sm"
           data-bs-toggle="collapse"
           href="#raw-response"
           role="button">
          Show raw Gemini response
        </a>
        <div class="collapse mt-2" id="raw-response">
          <pre class="bg-dark text-light p-3 rounded small" style="max-height: 400px; overflow-y: auto;"><%= @charter.gemini_raw %></pre>
        </div>
      </div>

      <%# AI disclaimer %>
      <p class="text-muted small fst-italic">
        Curricula are AI-generated starting points, not pedagogical advice. Adapt before using with your ring.
      </p>

    </div><%# /col-lg-9 %>

    <%# Right sidebar — artifact + invite suggestions %>
    <div class="col-lg-3">
      <div class="card artifact-sidebar">
        <div class="card-header d-flex align-items-center gap-2">
          <%= render "rings/concentric_ring_marker", current_week: 6, size: :sm %>
          <strong>What this ring is building</strong>
        </div>
        <div class="card-body">
          <p class="small"><%= @charter.artifact_template %></p>

          <h6 class="mt-3 text-muted small text-uppercase">Suggested voices</h6>
          <p class="small text-muted"><%= @charter.invite_suggestions %></p>
        </div>
      </div>
    </div><%# /col-lg-3 %>

  </div><%# /row %>

<% end %>
```

### 6.3 — Update concentric ring marker on index cards

In `rings/index.html.erb`, update the `current_week` local passed to `_concentric_ring_marker`:

```ruby
current_week: ring.learning_charter&.ring_sessions&.maximum(:week_number).to_i
```

This evaluates to 0 for draft rings (no charter), and to the highest completed week for complete rings.

---

## Manual Tests

Generate a curriculum first (Phase 5 must be complete). Then verify:

1. Show page for a complete ring renders the charter card with focus statement, learning goals list, success indicators list, and inquiry framework
2. Six session cards appear in the `.session-timeline` flex row
3. Timeline scrolls horizontally on a narrow browser window (resize to verify)
4. Each session card shows: Week N header, guiding question, resources list with "Suggested starting points" prefix, discussion prompts as ordered list, inquiry activity in italic
5. Right sidebar shows the artifact template in a sticky card with the concentric ring SVG (week 6, all filled)
6. Right sidebar shows "Suggested voices" with invite suggestions text
7. "Show raw Gemini response" toggle expands to reveal the raw JSON
8. AI disclaimer appears below the timeline: "Curricula are AI-generated starting points, not pedagogical advice."
9. Index page card for the complete ring shows the `Complete` badge
10. Concentric ring SVG on the index card shows all 6 circles filled (warm coral) for a complete ring

---

## RSpec Tests

Add to `spec/requests/rings_spec.rb`:

```bash
bundle exec rspec spec/requests/rings_spec.rb
```

```ruby
describe "GET /rings/:id (complete)" do
  let(:complete_ring) { create(:ring, :complete, user: user) }
  let(:charter) do
    create(:learning_charter,
           ring: complete_ring,
           focus_statement: "This ring studies peer learning dynamics.",
           artifact_template: "A one-page synthesis document.")
  end

  before do
    sign_in_as(user)
    6.times do |i|
      create(:ring_session,
             learning_charter: charter,
             week_number: i + 1,
             guiding_question: "Week #{i + 1} question")
    end
  end

  it "returns 200" do
    get ring_path(complete_ring)
    expect(response).to have_http_status(:ok)
  end

  it "includes the focus statement" do
    get ring_path(complete_ring)
    expect(response.body).to include("This ring studies peer learning dynamics.")
  end

  it "includes the artifact template" do
    get ring_path(complete_ring)
    expect(response.body).to include("A one-page synthesis document.")
  end

  it "includes all six session week headers" do
    get ring_path(complete_ring)
    (1..6).each do |week|
      expect(response.body).to include("Week #{week}")
    end
  end

  it "includes the raw response toggle" do
    get ring_path(complete_ring)
    expect(response.body).to include("raw-response")
  end

  it "includes the AI disclaimer" do
    get ring_path(complete_ring)
    expect(response.body).to include("AI-generated starting points")
  end
end
```

---

## Acceptance Criteria

- [ ] `_session_card.html.erb` partial renders week number, guiding question, resources with prefix, discussion prompts as ordered list, inquiry activity
- [ ] Complete state uses `@charter.learning_goals_list` and `@charter.success_indicators_list` — no manual `split` in the view
- [ ] `.session-timeline` flex container wraps six `_session_card` partials
- [ ] Raw response toggle uses Bootstrap collapse — no plain JS
- [ ] Right sidebar uses `.artifact-sidebar` (sticky) class
- [ ] Concentric ring SVG on sidebar shows `current_week: 6` (all filled)
- [ ] Index card SVG shows `current_week: 0` for draft rings, 6 for complete rings
- [ ] AI disclaimer appears at the bottom of every complete charter
- [ ] All RSpec cases pass
