# Phase 1 — Boilerplate Configuration

**Goal:** Customize the inherited Open Demo Starter boilerplate with StudyRings identity: accent colors, navbar links, footer disclaimer, env vars, and README.

**Depends on:** Open Demo Starter v2.0 boilerplate is already cloned and running (`bin/rails db:setup` succeeds, `bin/dev` starts cleanly).

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Sections 2, 11, 12

---

## Context

This phase touches only configuration and layout files. No new models, controllers, or routes are added. Every change is a substitution of a boilerplate default with a StudyRings-specific value.

The boilerplate uses a single `app/assets/stylesheets/application.css` (Propshaft, not Sprockets). The spec mentions `_accent.scss` — that is the production app's setup. Here, all custom CSS goes directly into `application.css` as plain CSS.

---

## Tasks

### 1.1 — Update `.env.example`

Set the three branding variables:

```
APP_NAME=StudyRings Demo
APP_TAGLINE=Pick a topic. Get a 6-week peer learning curriculum your ring can run itself.
APP_DESCRIPTION=An open source demo that generates a complete O.R.B.I.T. learning charter and 6-session curriculum for a peer learning ring, from a single topic prompt.
```

Leave `GEMINI_API_KEY=`, `AI_CALLS_PER_USER_PER_DAY=50`, `AI_GLOBAL_TIMEOUT_SECONDS=15` unchanged with their existing placeholders and comments.

### 1.2 — Update local `.env`

Copy the same three values into `.env` (local, gitignored). Keep the real `GEMINI_API_KEY` value that is already there.

### 1.3 — Update accent colors in `application.css`

In the `:root` block, replace the boilerplate accent values:

```css
:root {
  --accent: #b45309;
  --accent-hover: #92400e;
  --accent-secondary: #f87171;
}
```

### 1.4 — Add custom CSS classes to `application.css`

Append below the `:root` block:

```css
/* Accent button variant */
.btn-accent {
  background-color: var(--accent);
  border-color: var(--accent);
  color: #fff;
}
.btn-accent:hover,
.btn-accent:focus {
  background-color: var(--accent-hover);
  border-color: var(--accent-hover);
  color: #fff;
  box-shadow: 0 0 0 0.25rem rgba(180, 83, 9, 0.4);
}

/* Concentric ring marker sizing */
.ring-marker svg.size-sm { width: 32px;  height: 32px; }
.ring-marker svg.size-md { width: 48px;  height: 48px; }
.ring-marker svg.size-lg { width: 64px;  height: 64px; }

/* Horizontal session timeline */
.session-timeline {
  display: flex;
  gap: 1rem;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  padding-bottom: 1rem;
}
.session-timeline .session-card {
  min-width: 280px;
  scroll-snap-align: start;
}

/* Artifact sidebar */
.artifact-sidebar {
  position: sticky;
  top: 1rem;
}
```

### 1.5 — Update navbar in `app/views/layouts/application.html.erb`

Add a `Rings` nav link and a `New Ring` button, both visible only to signed-in users:

```erb
<% if signed_in? %>
  <li class="nav-item">
    <%= link_to "Rings", rings_path, class: "nav-link" %>
  </li>
<% end %>
```

And the `New Ring` button in the navbar right side (near the user dropdown):

```erb
<% if signed_in? %>
  <%= link_to "New Ring", new_ring_path, class: "btn btn-accent btn-sm me-2" %>
<% end %>
```

Do not change sign-in, sign-up, or sign-out logic.

### 1.6 — Update footer disclaimer in `app/views/layouts/application.html.erb`

Locate the existing AI disclaimer line. Add a second line directly beneath it:

```erb
<small class="text-muted d-block">
  Curricula are AI-generated starting points, not pedagogical advice. Adapt before using with your ring.
</small>
```

### 1.7 — Update `README.md`

Replace the boilerplate placeholder body with StudyRings content. Keep the Stack and License sections. Add the following sections:

- **What this is** — single-feature Rails 8 demo, generates O.R.B.I.T. curriculum from a topic prompt
- **Why I built this** — one feature from a larger multi-tenant SaaS product; this demo isolates the curriculum generation moment
- **The AI prompt is editable** — sign in as `demo@example.com / password123`, open `/admin/ai_templates`, edit `studyrings_curriculum_v1`
- **Setup** — `bin/setup`, `cp .env.example .env`, add Gemini API key, `bin/rails server`

---

## Manual Tests

Start the server (`bin/dev`) and verify:

1. Browser tab title shows `StudyRings Demo`
2. Navbar brand shows `StudyRings Demo`
3. Signed in as `demo@example.com / password123`: navbar shows `Rings` link and `New Ring` button
4. `New Ring` button is brown (accent), not Bootstrap default blue
5. Footer contains both the boilerplate AI disclaimer and the StudyRings-specific line `Curricula are AI-generated starting points, not pedagogical advice.`
6. The `Rings` and `New Ring` links are not visible when signed out
7. In `bin/rails console`: `ENV["APP_NAME"]` returns `"StudyRings Demo"`

---

## RSpec Tests

No new spec files in this phase. Run the inherited full suite to confirm nothing was broken:

```bash
bundle exec rspec
```

Expected: all existing tests pass with zero failures.

---

## Acceptance Criteria

- [ ] `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION` set in both `.env.example` (placeholder-safe) and `.env` (local)
- [ ] `--accent: #b45309`, `--accent-hover: #92400e`, `--accent-secondary: #f87171` defined in `application.css`
- [ ] `.btn-accent`, `.session-timeline`, `.artifact-sidebar`, `.ring-marker` size helpers present in `application.css`
- [ ] Navbar `Rings` link visible when signed in, hidden when signed out
- [ ] Navbar `New Ring` button uses `.btn-accent`, visible when signed in
- [ ] Footer has the StudyRings-specific AI disclaimer line
- [ ] `README.md` has all four app-specific sections
- [ ] Full existing RSpec suite passes
