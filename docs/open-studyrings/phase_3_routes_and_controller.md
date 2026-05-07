# Phase 3 — Routes and Controller Skeleton

**Goal:** Add all `rings` routes, create `RingsController` with every action implemented (except `generate`, which gets a stub), and verify access control.

**Depends on:** Phase 2 complete. `Ring` model exists and is valid.

**Spec reference:** `docs/open-studyrings/studyrings-demo-spec.md` — Sections 4, 5

---

## Context

`RingsController` is the single new controller for this app. All other controllers (auth, admin, health) are inherited from the boilerplate unchanged.

Every action in `RingsController` must:
1. Be protected by `before_action :require_authentication`
2. Scope all queries to `current_user` — never load rings without a user scope
3. Return 404 (not 403) if a ring belongs to a different user — achieved by scoping `find` to `current_user.rings`

The `/dashboard` route is remapped to `rings#index` so the boilerplate's post-login redirect lands on the rings list. The `DashboardController` is no longer used.

---

## Tasks

### 3.1 — Update `config/routes.rb`

The `resources :rings` block was pre-added in Phase 1 to satisfy the navbar helpers. The remaining change is to remap `/dashboard` from `dashboard#show` to `rings#index`:

```ruby
# Change this:
get  "/dashboard", to: "dashboard#show", as: :dashboard
# To this:
get  "/dashboard", to: "rings#index", as: :dashboard
```

Verify named route helpers: `rings_path`, `new_ring_path`, `ring_path(@ring)`, `generate_ring_path(@ring)`, `dashboard_path`.

### 3.2 — Create `app/controllers/rings_controller.rb`

```ruby
class RingsController < ApplicationController
  before_action :require_authentication
  before_action :set_ring, only: [:show, :destroy, :generate]

  rate_limit to: 10, within: 1.minute, only: [:generate],
             with: -> { redirect_to ring_path(@ring), alert: "Please wait before generating again." }

  def index
    @rings = current_user.rings.ordered
  end

  def new
    @ring = Ring.new
  end

  def create
    @ring = current_user.rings.build(ring_params)
    if @ring.save
      redirect_to ring_path(@ring), notice: "Ring created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @charter = @ring.learning_charter
    @sessions = @charter&.ring_sessions&.order(:week_number) || []
  end

  def destroy
    @ring.destroy
    redirect_to rings_path, notice: "Ring deleted."
  end

  def generate
    redirect_to ring_path(@ring), alert: "Generate not yet implemented."
  end

  private

  def set_ring
    @ring = current_user.rings.find(params[:id])
  end

  def ring_params
    params.require(:ring).permit(:topic, :member_background, :meeting_frequency, :purpose)
  end
end
```

`current_user.rings.find(params[:id])` automatically raises `ActiveRecord::RecordNotFound` and returns 404 if the ring belongs to a different user — no extra authorization check needed.

### 3.3 — Create placeholder views

These prevent 404s during manual testing. Full implementation comes in Phase 4.

**`app/views/rings/index.html.erb`**
```erb
<div class="container py-4">
  <h1>My Rings</h1>
</div>
```

**`app/views/rings/new.html.erb`**
```erb
<div class="container py-4">
  <h1>New Ring</h1>
</div>
```

**`app/views/rings/show.html.erb`**
```erb
<div class="container py-4">
  <h1><%= @ring.topic %></h1>
  <p>Status: <%= @ring.status %></p>
</div>
```

---

## Manual Tests

Sign in as `demo@example.com / password123` and verify:

1. `/dashboard` loads without error (renders rings#index placeholder)
2. `/rings` loads without error (same view)
3. `/rings/new` loads without error
4. Submit the new ring form with valid data (requires Phase 4 form — skip if not built yet; use `curl` or Rails console to verify the route exists)
5. `GET /rings/:id` for a ring you own returns 200
6. Access control: in console, create a second user (`User.create!(email: "other@example.com", password: "password123", password_confirmation: "password123")`), create a ring for them, then attempt to visit that ring's URL as `demo@example.com` — expect 404
7. `DELETE /rings/:id` for your own ring destroys it and redirects to `/rings`
8. `POST /rings/:id/generate` shows "Generate not yet implemented" alert
9. Unauthenticated `GET /rings` redirects to `/sign_in`
10. `bin/rails routes | grep ring` — confirms all 6 routes exist

---

## RSpec Tests

Create `spec/requests/rings_spec.rb` with the access control and CRUD suite.

```bash
bundle exec rspec spec/requests/rings_spec.rb
```

### Required coverage for this phase

```ruby
require "rails_helper"

RSpec.describe "Rings", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:ring)       { create(:ring, user: user) }

  # Authentication guard — every action
  describe "unauthenticated access" do
    it "redirects GET /rings to sign in"           { get rings_path;          expect(response).to redirect_to(sign_in_path) }
    it "redirects GET /rings/new to sign in"       { get new_ring_path;       expect(response).to redirect_to(sign_in_path) }
    it "redirects POST /rings to sign in"          { post rings_path;         expect(response).to redirect_to(sign_in_path) }
    it "redirects GET /rings/:id to sign in"       { get ring_path(ring);     expect(response).to redirect_to(sign_in_path) }
    it "redirects DELETE /rings/:id to sign in"    { delete ring_path(ring);  expect(response).to redirect_to(sign_in_path) }
    it "redirects POST generate to sign in"        { post generate_ring_path(ring); expect(response).to redirect_to(sign_in_path) }
  end

  # Create
  describe "POST /rings" do
    before { sign_in_as(user) }

    context "with valid params" do
      let(:valid_params) do
        { ring: { topic: "Network theory", member_background: "mixed",
                  meeting_frequency: "weekly", purpose: "We want to test this." } }
      end

      it "creates a ring with status draft" do
        expect { post rings_path, params: valid_params }.to change(Ring, :count).by(1)
        expect(Ring.last.status).to eq("draft")
        expect(Ring.last.user).to eq(user)
      end

      it "redirects to the ring show page" do
        post rings_path, params: valid_params
        expect(response).to redirect_to(ring_path(Ring.last))
      end
    end

    context "with blank topic" do
      it "returns 422 and re-renders the form" do
        post rings_path, params: { ring: { topic: "", member_background: "mixed",
                                           meeting_frequency: "weekly", purpose: "Test purpose here." } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # Access control on show / destroy / generate
  describe "accessing another user's ring" do
    let(:other_ring) { create(:ring, user: other_user) }
    before { sign_in_as(user) }

    it "returns 404 for GET /rings/:id"       { get ring_path(other_ring);          expect(response).to have_http_status(:not_found) }
    it "returns 404 for DELETE /rings/:id"    { delete ring_path(other_ring);        expect(response).to have_http_status(:not_found) }
    it "returns 404 for POST generate"        { post generate_ring_path(other_ring); expect(response).to have_http_status(:not_found) }
  end

  # Destroy
  describe "DELETE /rings/:id" do
    before { sign_in_as(user) }

    it "destroys the ring" do
      ring  # ensure created
      expect { delete ring_path(ring) }.to change(Ring, :count).by(-1)
    end

    it "redirects to rings_path" do
      delete ring_path(ring)
      expect(response).to redirect_to(rings_path)
    end
  end
end
```

---

## Acceptance Criteria

- [ ] `bin/rails routes | grep ring` shows all 6 routes: `index`, `new`, `create`, `show`, `destroy`, `generate`
- [ ] `/dashboard` maps to `rings#index`; `dashboard_path` helper works
- [ ] `before_action :require_authentication` covers all actions
- [ ] `set_ring` scopes to `current_user.rings` — other users' rings return 404
- [ ] `ring_params` permits only the four allowed fields
- [ ] Rate limiting configured on `generate` action
- [ ] All RSpec access control and CRUD cases pass
