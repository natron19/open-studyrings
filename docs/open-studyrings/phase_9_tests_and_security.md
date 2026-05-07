# Phase 9 — Complete RSpec Test Suite and Pre-Publish Security Check

**Goal:** Finalize all spec files to full coverage, run the complete suite with zero failures and zero real API calls, then execute the pre-publish security check before pushing to GitHub.

**Depends on:** Phases 1–8 complete. All features implemented.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Section 9  
**Security check:** `docs/prompts/pre-publish-security-check.md`

---

## Context

Each prior phase added RSpec cases incrementally. This phase closes the gaps: ensures every access control path is covered, every error path is covered, and the fixture is complete. Then it runs the pre-publish security check before the repo is made public.

The boilerplate specs (user, auth, admin, gemini_service, ai_gatekeeper, ai_budget_checker) are inherited unchanged. Do not rewrite them. Only write new specs for StudyRings domain code.

**No real Gemini API calls** in any test. All calls must be stubbed via `gemini_returns(...)` or `gemini_raises(...)` from `spec/support/gemini_test_double.rb`.

---

## Tasks

### 9.1 — Verify `spec/models/ring_spec.rb` is complete

Ensure all of these cases are present and passing:

- `topic` presence: blank fails
- `topic` length: 4 chars fails, 5 chars passes, 200 chars passes, 201 chars fails
- `member_background` inclusion: `"beginner"`, `"mixed"`, `"experienced"` pass; any other value fails
- `meeting_frequency` inclusion: `"weekly"`, `"biweekly"` pass; any other value fails
- `purpose` presence: blank fails
- `purpose` length: 9 chars fails, 10 chars passes, 500 chars passes, 501 chars fails
- `status` inclusion: `"draft"`, `"generating"`, `"complete"`, `"failed"` all pass; `"pending"` fails
- Default `status` is `"draft"` (verify with `Ring.new.status`)
- `belongs_to :user`: invalid without a user
- `has_one :learning_charter, dependent: :destroy`: destroying a ring destroys its charter
- Cascade: destroying a ring also destroys all its ring sessions (via charter)

### 9.2 — Verify `spec/models/learning_charter_spec.rb` is complete

- `ring_id` presence
- `ring_id` uniqueness: second charter for same ring fails
- `gemini_raw` presence: blank fails
- `has_many :ring_sessions, dependent: :destroy`: destroying a charter destroys its sessions
- `learning_goals_list`: `"Goal A\nGoal B\nGoal C"` → `["Goal A", "Goal B", "Goal C"]`
- `learning_goals_list`: blank lines filtered (e.g., `"Goal A\n\nGoal B"` → `["Goal A", "Goal B"]`)
- `success_indicators_list`: same behavior as `learning_goals_list`

### 9.3 — Verify `spec/models/ring_session_spec.rb` is complete

- `week_number` inclusion: 1–6 pass; 0 and 7 fail
- `week_number` uniqueness scoped to `learning_charter_id`: same week in same charter fails; same week in different charter passes
- `guiding_question` presence: blank fails
- `resources_list`: splits and filters blanks
- `discussion_prompts_list`: splits and filters blanks

### 9.4 — Complete `spec/requests/rings_spec.rb`

Ensure every listed case is present. Final required coverage:

**Authentication (all actions):**

```ruby
%i[
  get_rings get_new_ring post_rings get_ring
  delete_ring post_generate
].each do |action|
  it "redirects unauthenticated #{action} to sign in"
end
```

Write these as individual examples, one per action/verb.

**Create:**
- Valid params → ring created with `status: "draft"`, belongs to current user, redirects to show
- Invalid params (blank topic) → 422, form re-renders, no ring created

**Index:**
- No rings → 200, body includes "first ring" (empty state)
- With rings → 200, body includes ring topic

**Show states:**
- Draft ring → 200, body includes "Generate curriculum"
- Generating ring → 200, body includes "spinner-border" or "Drafting your charter"
- Complete ring → 200, body includes focus statement, six week headers, artifact template
- Failed ring → 200, body includes "Retry"

**Generate (success):**
- Calls `GeminiService.generate` with template `"studyrings_curriculum_v1"` and all four variables
- Creates one `LearningCharter`
- Creates exactly six `RingSession` records (verify count)
- Sets `ring.status` to `"complete"`
- Redirects to ring show

**Generate (errors):**
- `GeminiService::TimeoutError` → status `"failed"`, response body matches timeout message
- `GeminiService::BudgetExceededError` → status `"failed"`, response body matches budget message
- `GeminiService::GatekeeperError` → status `"failed"`, response body present
- `JSON::ParserError` → status `"failed"`, response body present

**Access control:**
- `GET /rings/:id` for another user's ring → 404
- `DELETE /rings/:id` for another user's ring → 404
- `POST generate` for another user's ring → 404

**Destroy:**
- Destroys ring (count decreases by 1)
- Destroys associated charter and sessions (cascade)
- Redirects to `rings_path`

### 9.5 — Verify `spec/fixtures/studyrings_curriculum_response.json`

Confirm the fixture file:
1. Is valid JSON (parse it in Ruby: `JSON.parse(File.read(...))`)
2. Has exactly 6 sessions in the `sessions` array
3. Each session has all required fields: `week_number`, `guiding_question`, `resources` (array), `discussion_prompts` (array), `inquiry_activity`
4. Top-level has: `focus_statement`, `learning_goals` (array), `success_indicators` (array), `inquiry_framework`, `invite_suggestions`, `artifact_template`

### 9.6 — Final RSpec run

```bash
bundle exec rspec --format documentation
```

Expected:
- Zero failures
- Zero pending (or documented reason for any skipped examples)
- Zero real Gemini API calls (watch for any test that doesn't stub)

Review the output for:
- Tests that say "0 examples" for a describe block (indicates a missing `let` or `before`)
- Tests that pass but seem too fast (may be no-ops if a stub is wrong)

---

## Pre-Publish Security Check

Before pushing this repo to GitHub, run the full security check defined in `docs/prompts/pre-publish-security-check.md`.

Copy and paste the prompt from that file into Claude Code and run it. The check covers:

1. **Hardcoded secrets** — scan all files for API keys, passwords, tokens
2. **Gitignore coverage** — `.env`, `master.key`, `*.key`, `log/`, `tmp/`
3. **`.env.example`** — confirm every value is a placeholder, not a real key
4. **`config/database.yml`** — no hardcoded credentials; production uses `ENV.fetch`
5. **`db/seeds.rb`** — no hardcoded credentials beyond the documented `password123` demo password
6. **`config/environments/production.rb`** — no hardcoded secrets
7. **Gemfile** — only `https://rubygems.org` as gem source
8. **README** — no internal URLs, server names, real email addresses
9. **Log and tmp files** — no tracked files with sensitive content
10. **Git history** — no commit messages suggesting a secret was ever committed

**Any finding must be resolved before the repo is made public.**

Common findings to fix:
- Real `GEMINI_API_KEY` in `.env` → already gitignored; verify with `git status`
- `config/master.key` → should be in `.gitignore`; verify
- `log/*.log` files tracked → `log/` should be in `.gitignore`

---

## RSpec Tests (Final Run)

```bash
bundle exec rspec --format documentation
```

Save the output. Review every line. Share failures with the maintainer before pushing.

---

## Acceptance Criteria

- [ ] `spec/models/ring_spec.rb` — all validation, association, and cascade cases present and passing
- [ ] `spec/models/learning_charter_spec.rb` — uniqueness, presence, helper methods present and passing
- [ ] `spec/models/ring_session_spec.rb` — week_number scoped uniqueness, helpers present and passing
- [ ] `spec/requests/rings_spec.rb` — full authentication, CRUD, generate (success + all errors), access control, destroy coverage
- [ ] `spec/fixtures/studyrings_curriculum_response.json` — valid JSON, 6 sessions, all required fields
- [ ] `bundle exec rspec --format documentation` — zero failures, zero real API calls
- [ ] Pre-publish security check executed and all findings resolved
- [ ] `.env` is gitignored and not tracked by git
- [ ] `config/master.key` is gitignored and not tracked by git
- [ ] No real API keys in any committed file
- [ ] `git log --oneline` shows no commit message suggesting a secret was committed
- [ ] Repo is ready to push to GitHub
