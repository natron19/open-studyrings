# StudyRings Demo

> Pick a topic. Get a 6-week peer learning curriculum your ring can run itself.

## What this is

A single-feature open source Rails 8 demo. You enter a topic, a member background level, a meeting frequency, and a one-sentence purpose. Gemini returns a complete O.R.B.I.T. learning charter (Origin, Rhythm, Build, Invite, Transform) and a 6-session curriculum that climbs Bloom's Taxonomy from Remember at Week 1 to Create at Week 6.

The output is a peer learning curriculum — questions to explore together, with a six-week arc designed to deepen over time, ending in an artifact the ring builds rather than a test the ring takes.

## Why I built this

This is one feature from a larger multi-tenant SaaS product I'm building called StudyRings, where small peer groups form around a shared curiosity, build a growing collection of learning materials together, and produce lasting artifacts of what they learned. The production app handles ongoing rings, sessions, resources, discussions, and ring health. This demo isolates the single moment that makes the rest of it work: the curriculum generation.

This demo is open source under MIT license. Clone it, edit it, ship your own.

## The AI prompt is editable

Sign in as `demo@example.com` / `password123` (admin), open `/admin/ai_templates`, and click `studyrings_curriculum_v1`. The test panel on the right runs any draft against Gemini without saving. When you have something better than what the seed file shipped with, save it — the next "Generate curriculum" click uses your version.

## Setup

```bash
bin/setup
cp .env.example .env
# Add your Gemini API key to .env
# Get a free key at https://aistudio.google.com/app/apikey
bin/rails server
```

Visit `http://localhost:3000` and sign in with `demo@example.com` / `password123`.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"StudyRings Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template (3000 tokens for the curriculum template)
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert with a retry button, never crash the page
- AI disclaimer in the footer on every page

**Deliberately omitted:**
- No content moderation API — the output is a peer learning curriculum; risk surface is low
- No fact-checking of resources — the view explicitly frames them as starting points, not citations
- No PII scrubbing — this is a local demo; the README warns not to put real personal data in the purpose field

## License

MIT — see [LICENSE](LICENSE)
