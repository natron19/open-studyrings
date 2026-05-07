# Phase 4 — Core Views

**Goal:** Implement all views except the complete charter display and generating spinner (those come in Phases 5–7): the home page override, rings index, new ring form, show page draft/failed states, concentric ring SVG marker partial, and the print Stimulus controller.

**Depends on:** Phase 3 complete. `RingsController` exists with placeholder views.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Sections 6, 12

---

## Context

**No plain JavaScript.** The only JS in this phase is a Stimulus controller for the print button. `window.print()` cannot be called via `onclick=` due to CSP.

**`turbo_stream.update()` only** — if any Turbo Stream is added later, never use `replace()`.

All views use Bootstrap 5 dark mode utilities. No inline styles except where CSS variables are explicitly referenced.

The concentric ring SVG marker is a pure inline SVG partial. Six concentric circles, no animation. Completed weeks are filled with `var(--accent-secondary)` (warm coral); future weeks are outlined with `var(--accent)` stroke.

---

## Tasks

### 4.1 — Override `app/views/home/index.html.erb`

Public landing page. No auth required (`HomeController` skips authentication).

Structure:
1. **Hero** — `<h1>` with `APP_NAME`, `<p>` with `APP_TAGLINE`, and a `Sign up` CTA linking to `sign_up_path` styled `.btn-accent btn-lg`
2. **Three-column callout** — Bootstrap `row` with three `col-md-4` cards: `Origin & Rhythm` (focus + structure), `Build & Invite` (inquiry + external voices), `Transform` (the artifact the ring produces)
3. **Static example charter card** — hardcoded example showing what output looks like. Topic: "Network theory and how communities actually organize". Show a focus statement, two learning goals, and a single Week 1 guiding question. Wrap in a Bootstrap `card` with a subdued border.
4. CTA at bottom: `Sign up to create your first Ring →` linking to `sign_up_path`

Use `ENV.fetch("APP_NAME", "StudyRings Demo")` and `ENV.fetch("APP_TAGLINE", "")` for all branding text.

### 4.2 — Create `app/views/rings/_concentric_ring_marker.html.erb`

Inline SVG partial. Accepts two locals:
- `current_week` (integer, 0–6): weeks 1 through `current_week` are filled; 0 means none filled
- `size` (symbol, default `:md`): maps to CSS class `size-sm`, `size-md`, `size-lg`

Implementation: six concentric circles, radii evenly spaced (e.g., 4, 8, 12, 16, 20, 24 within a 28×28 viewBox or similar). For each circle `i` (1–6): if `i <= current_week`, `fill="var(--accent-secondary)" stroke="none"`; else `fill="none" stroke="var(--accent)" stroke-width="1.5"`.

```erb
<%# locals: (current_week: 0, size: :md) %>
<span class="ring-marker">
  <svg class="<%= "size-#{size}" %>" viewBox="0 0 56 56" xmlns="http://www.w3.org/2000/svg">
    <% [4, 8, 13, 19, 24, 28].each_with_index do |r, i| %>
      <% week = i + 1 %>
      <% if week <= current_week %>
        <circle cx="28" cy="28" r="<%= r %>" fill="var(--accent-secondary)" />
      <% else %>
        <circle cx="28" cy="28" r="<%= r %>" fill="none" stroke="var(--accent)" stroke-width="1.5" />
      <% end %>
    <% end %>
  </svg>
</span>
```

### 4.3 — Implement `app/views/rings/index.html.erb`

```
Page header row:
  Left: <h1>My Rings</h1>
  Right: "New Ring" button (.btn-accent) → new_ring_path

If @rings.empty?:
  Empty state card: "Your first ring is one click away"
  Show the same static example charter card from the home page
  CTA: "Create your first Ring" → new_ring_path

Else:
  Bootstrap row card grid
  For each ring:
    Bootstrap col-md-6 col-lg-4
    Card:
      Top-right status badge:
        draft      → badge bg-secondary "Not started"
        generating → badge using var(--accent) "Generating..."
        complete   → badge using var(--accent) "Complete"
        failed     → badge bg-danger "Failed"
      Card body:
        Left glyph: _concentric_ring_marker partial
          current_week: ring.learning_charter&.ring_sessions&.maximum(:week_number) || 0
          size: :md
        Topic in bold
        Member background label (capitalize)
        Meeting frequency label (capitalize)
        "Created N days ago" (time_ago_in_words)
      Full card is a link (stretched-link) to ring_path(ring)
```

### 4.4 — Implement `app/views/rings/new.html.erb`

Single-column form. Show validation errors at the top if `@ring.errors.any?`.

```erb
<div class="container py-4">
  <div class="row justify-content-center">
    <div class="col-md-8 col-lg-6">
      <h1 class="mb-4">New Ring</h1>

      <% if @ring.errors.any? %>
        <div class="alert alert-danger">
          <ul class="mb-0">
            <% @ring.errors.full_messages.each do |msg| %>
              <li><%= msg %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%= form_with model: @ring do |f| %>
        <!-- topic: text_field -->
        <!-- member_background: radio group (Beginner / Mixed / Experienced) -->
        <!-- meeting_frequency: radio group (Weekly / Biweekly) -->
        <!-- purpose: textarea, rows: 2, helper text "One sentence. Why does this ring exist?" -->
        <!-- submit: "Create ring", class: "btn btn-accent" -->
      <% end %>
    </div>
  </div>
</div>
```

Use Bootstrap `form-label`, `form-control`, `form-check`, `form-text` classes throughout. The radio groups use `form-check form-check-inline`.

### 4.5 — Implement `app/views/rings/show.html.erb` — draft and failed states only

Page header:
- `<h1>` with `@ring.topic`
- `Delete ring` link: `link_to "Delete ring", ring_path(@ring), data: { turbo_method: :delete, turbo_confirm: "Delete this ring and its curriculum?" }, class: "btn btn-outline-danger btn-sm"`
- `Print` link: `<a href="#" data-controller="print" data-action="click->print#print" class="btn btn-outline-secondary btn-sm">Print</a>`

Four states (use `case @ring.status` or chained `if/elsif`):

**Draft state** (`status == "draft"`):
```erb
<div class="card mb-4">
  <div class="card-body">
    <dl class="row mb-0">
      <dt class="col-sm-3">Topic</dt>        <dd class="col-sm-9"><%= @ring.topic %></dd>
      <dt class="col-sm-3">Background</dt>   <dd class="col-sm-9"><%= @ring.member_background.capitalize %></dd>
      <dt class="col-sm-3">Frequency</dt>    <dd class="col-sm-9"><%= @ring.meeting_frequency.capitalize %></dd>
      <dt class="col-sm-3">Purpose</dt>      <dd class="col-sm-9"><%= @ring.purpose %></dd>
    </dl>
  </div>
</div>

<p class="text-muted">
  This will use 1 of your <%= ENV.fetch("AI_CALLS_PER_USER_PER_DAY", "50") %> daily AI calls.
</p>

<%= form_with url: generate_ring_path(@ring), method: :post do |f| %>
  <%= f.submit "Generate curriculum", class: "btn btn-accent btn-lg" %>
<% end %>
```

**Generating state** (`status == "generating"`):
Placeholder for now — `<p>Generating…</p>`. Full implementation in Phase 7.

**Complete state** (`status == "complete"`):
Placeholder: `<p class="text-success">Charter ready — coming in Phase 6.</p>`. Full implementation in Phase 6.

**Failed state** (`status == "failed"`):
```erb
<%= render "shared/ai_error", error_type: :error %>
<%= form_with url: generate_ring_path(@ring), method: :post do |f| %>
  <%= f.submit "Retry", class: "btn btn-accent mt-3" %>
<% end %>
```

### 4.6 — Create `app/javascript/controllers/print_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  print() {
    window.print()
  }
}
```

Register in `app/javascript/controllers/index.js` using the standard `application.register("print", ...)` pattern (or via the auto-loader if the boilerplate uses it).

---

## Manual Tests

Sign in and verify:

1. `GET /` (home) — StudyRings landing page renders: hero, three-column callout, static example charter card, CTA
2. `GET /rings` with no rings — empty state with "Your first ring is one click away" message and CTA
3. Click `New Ring` — form renders with all four fields (topic text input, two radio groups, purpose textarea)
4. Submit with all valid fields — ring created, redirected to show page with draft state
5. Show page displays the four ring inputs in a summary card, daily calls note, and `Generate curriculum` button
6. Submit the new ring form with blank topic — 422, form re-renders with error message "Topic can't be blank" or similar
7. After creating a ring, `GET /rings` shows the ring card with the concentric ring SVG marker (all outlines, none filled) and "Not started" badge
8. `Generate curriculum` button is brown (accent), not default blue
9. `Delete ring` button on show page shows a confirm dialog and then deletes + redirects
10. Print link triggers browser print dialog (not a navigation or error)
11. The print Stimulus controller loads — inspect browser console for no JS errors

---

## RSpec Tests

No new spec files. Add view-content assertions to the existing `spec/requests/rings_spec.rb`.

```bash
bundle exec rspec spec/requests/rings_spec.rb
```

Add these cases:

```ruby
describe "GET /rings" do
  before { sign_in_as(user) }

  context "with no rings" do
    it "returns 200 and mentions first ring" do
      get rings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("first ring")
    end
  end

  context "with rings" do
    before { create(:ring, user: user, topic: "Network theory and community") }

    it "returns 200 and includes the ring topic" do
      get rings_path
      expect(response.body).to include("Network theory and community")
    end
  end
end

describe "GET /rings/new" do
  before { sign_in_as(user) }

  it "returns 200 with the form fields" do
    get new_ring_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("topic")
    expect(response.body).to include("member_background")
    expect(response.body).to include("meeting_frequency")
    expect(response.body).to include("purpose")
  end
end

describe "GET /rings/:id (draft)" do
  before { sign_in_as(user) }

  it "returns 200 and includes Generate curriculum button" do
    get ring_path(ring)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Generate curriculum")
  end
end
```

---

## Acceptance Criteria

- [ ] Home page renders with env var branding (no hardcoded "StudyRings Demo" strings in view)
- [ ] `_concentric_ring_marker` partial renders inline SVG; `current_week: 0` = all outlines; `current_week: 3` = 3 filled + 3 outlined
- [ ] Index empty state shows CTA to `/rings/new`
- [ ] Index card grid shows topic, background, frequency, created-at, status badge, and SVG marker
- [ ] New ring form shows all four fields with validation errors when submitted blank
- [ ] Show page draft state: summary card, daily-calls note, and accent `Generate curriculum` button
- [ ] Show page failed state: error partial and accent `Retry` button
- [ ] `Delete ring` uses Turbo confirm — no plain `onclick`
- [ ] Print uses `print_controller.js` — no `onclick` on the anchor
- [ ] All RSpec cases pass
