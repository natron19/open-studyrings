# Phase 8 — Seed Data and Finishing Touches

**Goal:** Add the example ring to `db/seeds.rb`, remove unused boilerplate artifacts, ensure all buttons use `.btn-accent` consistently, and verify the complete first-run experience end-to-end.

**Depends on:** Phases 1–7 complete. Full generate flow works. All views render correctly.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Sections 10, 2

---

## Context

This is a cleanup and integration phase. The tasks are small individually but together ensure a clean first-run experience for anyone who clones the repo. Every task here is a finishing touch, not new functionality.

The seed must be idempotent — `bin/rails db:seed` should run twice without errors or duplicate records. Use `find_or_create_by!` for all domain records.

---

## Tasks

### 8.1 — Add example ring to `db/seeds.rb`

```ruby
demo_user = User.find_by!(email: "demo@example.com")

Ring.find_or_create_by!(
  user:  demo_user,
  topic: "Network theory and how communities actually organize"
) do |r|
  r.member_background  = "mixed"
  r.meeting_frequency  = "biweekly"
  r.purpose            = "Three of us keep arguing about whether 'community' has any concrete meaning, and we want to read together until we have a useful answer."
  r.status             = "draft"
end

puts "Seeded: example ring for demo user"
```

The ring is left in `draft` status intentionally. The first-run visitor clicks `Generate curriculum` themselves — this makes the AI flow the first thing they do.

Run: `bin/rails db:seed` (confirm idempotent with a second run).

### 8.2 — Audit `.env.example`

Confirm every value is a placeholder or safe default — no real keys:

```
APP_NAME=StudyRings Demo
APP_TAGLINE=Pick a topic. Get a 6-week peer learning curriculum your ring can run itself.
APP_DESCRIPTION=An open source demo that generates a complete O.R.B.I.T. learning charter and 6-session curriculum for a peer learning ring, from a single topic prompt.
GEMINI_API_KEY=             # Get your free key at https://aistudio.google.com/app/apikey
AI_CALLS_PER_USER_PER_DAY=50
AI_GLOBAL_TIMEOUT_SECONDS=15
```

All six variables should be present with inline comments for `GEMINI_API_KEY`.

### 8.3 — Verify `dashboard_path` helper works throughout

Check that no view or spec uses a hardcoded `/dashboard` string where `dashboard_path` should be used. Search:

```bash
grep -r '"/dashboard"' app/ spec/
```

Any hits should be replaced with `dashboard_path`.

### 8.4 — Remove or repurpose `app/views/dashboard/show.html.erb`

The `/dashboard` route now maps to `rings#index`. `DashboardController` is no longer in the request path.

Options:
- If `DashboardController` still exists and `app/views/dashboard/show.html.erb` still exists, delete both — they are unreachable.
- If any spec references `DashboardController`, update it to test `rings#index` instead.

Verify: `bin/rails routes | grep dashboard` returns `dashboard GET /dashboard rings#index`.

### 8.5 — Remove `demo_placeholder_v1` template if present

Check if the boilerplate seeded a `demo_placeholder_v1` AI template:

```ruby
AiTemplate.find_by(name: "demo_placeholder_v1")
```

If it exists in `db/seeds.rb`, remove it from the seeds file. If it exists in the database, drop it:

```ruby
AiTemplate.find_by(name: "demo_placeholder_v1")&.destroy
```

The only templates in a clean StudyRings seed should be `health_ping` and `studyrings_curriculum_v1`.

### 8.6 — CSS consistency audit

Confirm `.btn-accent` is applied to every primary action button. Open each view and check:

| Button | Expected class |
|---|---|
| `Create ring` (new form submit) | `.btn.btn-accent` |
| `Generate curriculum` (show page) | `.btn.btn-accent.btn-lg` |
| `Retry` (show page failed state) | `.btn.btn-accent` |
| `New Ring` (navbar) | `.btn.btn-accent.btn-sm` |
| `New Ring` (index page header) | `.btn.btn-accent` |
| Sign up CTA (home page) | `.btn.btn-accent.btn-lg` |

No primary action should use Bootstrap's default `.btn-primary` (blue). Secondary/cancel actions may use `.btn-outline-secondary` or `.btn-outline-danger`.

---

## Manual Tests

Full walkthrough from a clean state:

1. `bin/rails db:reset db:seed`
2. `bin/dev` (start server manually in a separate terminal)
3. Visit `http://localhost:3000` — StudyRings landing page renders with hero, three columns, example card
4. Click `Sign up` — register a new account (not the demo account)
5. Redirected to `/dashboard` — rings index shows empty state "Your first ring is one click away"
6. Click `New Ring` — fill in all four fields, submit
7. Show page appears with draft state and brown `Generate curriculum` button
8. Click `Generate curriculum` — generating spinner may appear; page transitions to complete state
9. Charter renders with focus statement, learning goals, six session cards
10. Return to `/rings` — card shows `Complete` badge and filled concentric ring SVG
11. Sign out
12. Sign in as `demo@example.com / password123`
13. `/rings` shows the pre-seeded draft ring "Network theory and how communities actually organize"
14. Generate the curriculum for that ring
15. Visit `/admin/llm_requests` — shows both AI calls in the log
16. Visit `/admin/ai_templates` — shows `studyrings_curriculum_v1` and `health_ping` (only two templates)
17. Click `studyrings_curriculum_v1` → Edit — test panel shows four variable inputs
18. Run the test panel with sample values — response renders inline
19. Visit `/up/llm` — returns `{"status":"ok",...}` with the real API key

---

## RSpec Tests

Run the full suite:

```bash
bundle exec rspec
```

Expected: all tests pass, zero failures, zero real API calls.

Check for any test that references `DashboardController` or `/dashboard` string paths — update to use `rings#index` and `dashboard_path`.

---

## Acceptance Criteria

- [ ] `db/seeds.rb` creates the example draft ring with the correct `topic`, `member_background`, `meeting_frequency`, `purpose`, and `status: "draft"`
- [ ] `bin/rails db:seed` is idempotent (no errors on second run, no duplicate records)
- [ ] `.env.example` has all 6 variables with placeholder values and a comment on `GEMINI_API_KEY`
- [ ] `dashboard_path` helper works — no hardcoded `/dashboard` strings in views or specs
- [ ] `DashboardController` and `dashboard/show.html.erb` removed (or confirmed unreachable)
- [ ] `demo_placeholder_v1` template removed from seeds and database
- [ ] All primary action buttons use `.btn-accent`
- [ ] Full end-to-end walkthrough completes without errors
- [ ] Full RSpec suite passes
