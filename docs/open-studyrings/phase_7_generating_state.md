# Phase 7 — Generating State and Stimulus Poller

**Goal:** Implement the intermediate generating state with a spinner and an auto-reload Stimulus controller so users see feedback during the (synchronous) Gemini call.

**Depends on:** Phase 6 complete. The show page renders draft, complete, and failed states correctly.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Section 6 (Show page, Generating state)

---

## Context

The `generate` action is **synchronous** — it runs the full Gemini call in the request cycle. The generating state exists to handle the gap between when the user submits the form and when the redirect arrives. In practice, on a fast connection with a fast Gemini response, the user may not see the generating state at all. That is acceptable. Its purpose is graceful handling of 8–15 second responses.

**Implementation approach:** The simplest reliable pattern for this app is:
- `ring.status = "generating"` is set at the top of the `generate` action (before the API call)
- If the browser receives a redirect (success), it goes to the complete state
- If the response is slow and the browser re-requests `/rings/:id` while the action is still in-flight, the show page renders the generating state
- The `ring-poller` Stimulus controller auto-reloads the page every 3 seconds when the generating state is visible, so the user sees it flip to complete or failed

**No Turbo Frames required.** A simple `location.reload()` on a timer is sufficient and avoids the complexity of frame polling.

---

## Tasks

### 7.1 — Create `app/javascript/controllers/ring_poller_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => {
      location.reload()
    }, 3000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
```

Register in `app/javascript/controllers/index.js` (or via the auto-loader if the boilerplate uses it).

### 7.2 — Update `app/views/rings/show.html.erb` — generating state

Replace the `<p>Generating…</p>` placeholder with the full generating state:

```erb
<%# Generating state — shown when @ring.status == "generating" %>
<% elsif @ring.status == "generating" %>
  <div class="text-center py-5" data-controller="ring-poller">
    <div class="spinner-border text-warning mb-3" style="width: 3rem; height: 3rem;" role="status">
      <span class="visually-hidden">Loading...</span>
    </div>
    <p class="text-muted">Drafting your charter and six sessions. This usually takes 8 to 15 seconds.</p>
  </div>
```

The `data-controller="ring-poller"` on the wrapping div activates the Stimulus controller only when this state is visible. When the page reloads and the status is no longer `generating`, this div is gone and the controller disconnects cleanly.

---

## Manual Tests

To test the generating state without waiting for a real Gemini call:

**Step 1 — Set a ring to generating via console:**
```ruby
ring = Ring.find_by(user: User.find_by(email: "demo@example.com"))
ring.update!(status: "generating")
```

**Step 2 — Visit `/rings/:id`** and verify:
1. Spinner appears (Bootstrap `spinner-border text-warning`)
2. Text reads "Drafting your charter and six sessions. This usually takes 8 to 15 seconds."
3. Page auto-reloads approximately every 3 seconds (watch the browser refresh indicator)

**Step 3 — Flip status back in console while watching the page:**
```ruby
ring.reload.update!(status: "complete")
```

4. Next reload shows the complete charter (Phase 6 output)

**Step 4 — End-to-end test (optional, requires live Gemini key):**
- Create a new ring, click `Generate curriculum`
- Gemini is often fast enough that the generating state is never visible — this is fine
- The state exists for slow responses; it does not need to always appear

---

## RSpec Tests

Add to `spec/requests/rings_spec.rb`:

```bash
bundle exec rspec spec/requests/rings_spec.rb
```

```ruby
describe "GET /rings/:id (generating)" do
  let(:generating_ring) { create(:ring, :generating, user: user) }
  before { sign_in_as(user) }

  it "returns 200" do
    get ring_path(generating_ring)
    expect(response).to have_http_status(:ok)
  end

  it "includes spinner or generating message" do
    get ring_path(generating_ring)
    expect(response.body).to match(/spinner-border|Drafting your charter/i)
  end

  it "includes the ring-poller data controller" do
    get ring_path(generating_ring)
    expect(response.body).to include("ring-poller")
  end
end
```

---

## Acceptance Criteria

- [ ] `ring_poller_controller.js` created and registered
- [ ] Controller calls `location.reload()` after 3 seconds on `connect()`
- [ ] Controller clears the timer on `disconnect()` (no memory leaks)
- [ ] Generating state renders spinner and message text
- [ ] `data-controller="ring-poller"` is on the generating state div — not on the page body
- [ ] Stimulus controller only activates when the generating state is visible
- [ ] When status flips to `complete` or `failed`, next page reload shows the correct state
- [ ] All RSpec cases pass
