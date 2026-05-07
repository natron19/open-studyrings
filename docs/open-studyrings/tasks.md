# StudyRings Demo — Build Task Tracker

**Spec:** [`studyrings-demo-spec.md`](studyrings-demo-spec.md)  
**Boilerplate:** Open Demo Starter v2.0  
**Status key:** `[ ]` todo · `[x]` done · `[~]` in progress

Work through phases in order. Complete every task in a phase, run the manual tests, run the RSpec tests, then move to the next phase.

> Never run `rails server`, `bin/dev`, or `bundle exec rspec` automatically. Always ask the user to run them manually.

---

## Phase 1 — Boilerplate Configuration ✅
**Spec:** [phase_1_boilerplate_config.md](phase_1_boilerplate_config.md)

- [x] `.env.example` — set `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION`
- [x] `.env` (local) — same three values + existing `GEMINI_API_KEY`
- [x] `application.css` — accent `#b45309`, hover `#92400e`, secondary `#f87171`
- [x] `application.css` — `.btn-accent`, `.session-timeline`, `.artifact-sidebar`, `.ring-marker` helpers
- [x] Navbar — `Rings` link + `New Ring` button (signed-in only); rings routes pre-stubbed in `routes.rb`
- [x] Footer — StudyRings AI disclaimer line added
- [x] `README.md` — app-specific sections (What this is, Why built, Prompt editing, Setup)
- [x] Existing RSpec suite passes with zero failures — run manually to confirm

---

## Phase 2 — Data Models ✅
**Spec:** [phase_2_data_models.md](phase_2_data_models.md)

- [x] Migration: `rings` table (uuid pk, user_id fk, topic, member_background, meeting_frequency, purpose, status)
- [x] Migration: `learning_charters` table (uuid pk, ring_id unique fk, text fields, gemini_raw)
- [x] Migration: `ring_sessions` table (uuid pk, learning_charter_id fk, week_number, text fields)
- [x] `bin/rails db:migrate` succeeds
- [x] `Ring` model — validations, associations, `ordered` scope
- [x] `LearningCharter` model — validations, `learning_goals_list`, `success_indicators_list`
- [x] `RingSession` model — validations, scoped uniqueness, `resources_list`, `discussion_prompts_list`
- [x] `spec/factories/rings.rb` — with `:complete`, `:failed`, `:generating` traits
- [x] `spec/factories/learning_charters.rb`
- [x] `spec/factories/ring_sessions.rb`
- [x] Model specs pass: `ring_spec.rb`, `learning_charter_spec.rb`, `ring_session_spec.rb`

---

## Phase 3 — Routes and Controller Skeleton ✅
**Spec:** [phase_3_routes_and_controller.md](phase_3_routes_and_controller.md)

- [x] `config/routes.rb` — `resources :rings` with `member { post :generate }`, `/dashboard` → `rings#index`
- [x] `RingsController` — all actions with `require_authentication`, `set_ring` scoped to `current_user`
- [x] Rate limiting on `generate` action (10/minute)
- [x] Placeholder views — `index`, `new`, `show`
- [x] `generate` stub redirects with alert
- [x] Request specs pass: unauthenticated redirects, create valid/invalid, access control, destroy

---

## Phase 4 — Core Views ✅
**Spec:** [phase_4_core_views.md](phase_4_core_views.md)

- [x] `home/index.html.erb` — hero, three-column callout, static example card, sign-up CTA
- [x] `rings/_concentric_ring_marker.html.erb` — inline SVG, `current_week` + `size` locals
- [x] `rings/index.html.erb` — empty state + card grid with SVG marker and status badge
- [x] `rings/new.html.erb` — four-field form, validation errors, `.btn-accent` submit
- [x] `rings/show.html.erb` — draft state (inputs summary + generate button) + failed state (error partial + retry)
- [x] `print_controller.js` — Stimulus controller calling `window.print()`
- [x] Request specs pass: empty index, index with rings, new form, draft show state

---

## Phase 5 — AI Integration ✅
**Spec:** [phase_5_ai_integration.md](phase_5_ai_integration.md)

- [x] `db/seeds.rb` — `studyrings_curriculum_v1` template (full prompts, `gemini-2.5-flash`, tokens 3000, temp 0.6)
- [x] `bin/rails db:seed` — runs idempotently
- [x] `spec/fixtures/studyrings_curriculum_response.json` — valid JSON, all 6 sessions
- [x] `RingsController#generate` — full implementation: status transitions, GeminiService call, JSON parse, transaction, all error rescues
- [x] Request specs pass: success creates charter + 6 sessions, all error paths set `status: "failed"`

---

## Phase 6 — Complete State View ✅
**Spec:** [phase_6_complete_view.md](phase_6_complete_view.md)

- [x] `rings/_session_card.html.erb` — week header, guiding question, resources (with "Suggested starting points" prefix), discussion prompts, inquiry activity
- [x] `rings/show.html.erb` complete state — charter card, `.session-timeline`, right sidebar, raw response toggle, AI disclaimer
- [x] Concentric ring SVG on index cards reflects actual `week_number` max
- [x] Request specs pass: complete show includes focus statement, 6 sessions, artifact template

---

## Phase 7 — Generating State ✅
**Spec:** [phase_7_generating_state.md](phase_7_generating_state.md)

- [x] `ring_poller_controller.js` — Stimulus controller, 3-second reload, clears timer on disconnect
- [x] `rings/show.html.erb` generating state — spinner + text + `data-controller="ring-poller"`
- [x] Request specs pass: generating show includes spinner or "Drafting" text

---

## Phase 8 — Seed Data and Cleanup ✅
**Spec:** [phase_8_seed_and_cleanup.md](phase_8_seed_and_cleanup.md)

- [x] `db/seeds.rb` — example draft ring for demo user (Network theory topic)
- [x] `.env.example` — all 6 variables confirmed as placeholders with comments
- [x] `dashboard_path` helper used throughout (no hardcoded `/dashboard` strings)
- [x] Unused `DashboardController` and `dashboard/show.html.erb` removed
- [x] `demo_placeholder_v1` template removed from seeds and database
- [x] All primary buttons use `.btn-accent` consistently
- [x] Full RSpec suite passes

---

## Phase 9 — Complete Tests + Security Check ✅
**Spec:** [phase_9_tests_and_security.md](phase_9_tests_and_security.md)

- [x] `ring_spec.rb` — all validation, association, cascade cases present
- [x] `learning_charter_spec.rb` — uniqueness, helpers present
- [x] `ring_session_spec.rb` — scoped uniqueness, helpers present
- [x] `rings_spec.rb` — full auth, CRUD, generate (success + all 4 error types), access control, destroy
- [x] `spec/fixtures/studyrings_curriculum_response.json` — valid, 6 sessions, all fields
- [x] `bundle exec rspec --format documentation` — zero failures, zero real API calls
- [x] Pre-publish security check run (see `docs/prompts/pre-publish-security-check.md`)
- [x] All security check findings resolved — all clean
- [x] `.env` and `config/master.key` confirmed gitignored and not tracked
- [x] Git history clean — one "first commit", no secrets

---

## Summary

| Phase | Description | Status |
|---|---|---|
| 1 | Boilerplate Configuration | [ ] |
| 2 | Data Models | [ ] |
| 3 | Routes and Controller Skeleton | [ ] |
| 4 | Core Views | [ ] |
| 5 | AI Integration | [ ] |
| 6 | Complete State View | [ ] |
| 7 | Generating State | [ ] |
| 8 | Seed Data and Cleanup | [ ] |
| 9 | Complete Tests + Security Check | ✅ |
