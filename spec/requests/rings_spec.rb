require "rails_helper"

RSpec.describe "Rings", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:ring)       { create(:ring, user: user) }

  # ── Authentication guard ────────────────────────────────────────────────────

  describe "unauthenticated access" do
    it "redirects GET /rings to sign in" do
      get rings_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET /rings/new to sign in" do
      get new_ring_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects POST /rings to sign in" do
      post rings_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects GET /rings/:id to sign in" do
      get ring_path(ring)
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects DELETE /rings/:id to sign in" do
      delete ring_path(ring)
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects POST /rings/:id/generate to sign in" do
      post generate_ring_path(ring)
      expect(response).to redirect_to(sign_in_path)
    end
  end

  # ── Create ──────────────────────────────────────────────────────────────────

  describe "POST /rings" do
    before { sign_in_as(user) }

    let(:valid_params) do
      { ring: { topic: "Network theory and community organizing",
                member_background: "mixed",
                meeting_frequency: "weekly",
                purpose: "We want to understand how networks shape communities." } }
    end

    context "with valid params" do
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
      it "returns 422 and does not create a ring" do
        expect {
          post rings_path, params: { ring: { topic: "",
                                             member_background: "mixed",
                                             meeting_frequency: "weekly",
                                             purpose: "Test purpose here." } }
        }.not_to change(Ring, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── Index ───────────────────────────────────────────────────────────────────

  describe "GET /rings" do
    before { sign_in_as(user) }

    context "with no rings" do
      it "returns 200 and shows empty state" do
        get rings_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("first ring")
      end
    end

    context "with rings" do
      before { create(:ring, user: user, topic: "Network theory and community") }

      it "returns 200 and includes the ring topic" do
        get rings_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Network theory and community")
      end
    end
  end

  # ── New ─────────────────────────────────────────────────────────────────────

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

  # ── Show states ─────────────────────────────────────────────────────────────

  describe "GET /rings/:id" do
    before { sign_in_as(user) }

    it "returns 200 for a draft ring with Generate curriculum button" do
      get ring_path(ring)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Generate curriculum")
    end

    it "returns 200 for a generating ring with spinner" do
      generating_ring = create(:ring, :generating, user: user)
      get ring_path(generating_ring)
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/spinner-border|Drafting your charter/i)
      expect(response.body).to include("ring-poller")
    end

    it "returns 200 for a failed ring with Retry button" do
      failed_ring = create(:ring, :failed, user: user)
      get ring_path(failed_ring)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Retry")
    end

    context "for a complete ring" do
      let(:complete_ring) { create(:ring, :complete, user: user) }
      let!(:charter) do
        create(:learning_charter,
               ring:               complete_ring,
               focus_statement:    "This ring studies peer learning dynamics in depth.",
               artifact_template:  "A one-page synthesis document.")
      end

      before do
        (1..6).each do |n|
          create(:ring_session,
                 learning_charter: charter,
                 week_number:      n,
                 guiding_question: "Week #{n} question")
        end
      end

      it "returns 200" do
        get ring_path(complete_ring)
        expect(response).to have_http_status(:ok)
      end

      it "includes the focus statement" do
        get ring_path(complete_ring)
        expect(response.body).to include("This ring studies peer learning dynamics in depth.")
      end

      it "includes the artifact template" do
        get ring_path(complete_ring)
        expect(response.body).to include("A one-page synthesis document.")
      end

      it "includes all six week headers" do
        get ring_path(complete_ring)
        (1..6).each { |n| expect(response.body).to include("Week #{n}") }
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
  end

  # ── Generate ────────────────────────────────────────────────────────────────

  describe "POST /rings/:id/generate" do
    before { sign_in_as(user) }

    let(:fixture_response) do
      File.read(Rails.root.join("spec/fixtures/studyrings_curriculum_response.json"))
    end

    context "with a successful Gemini response" do
      before { gemini_returns(fixture_response) }

      it "calls GeminiService with the correct template and variables" do
        expect(GeminiService).to receive(:generate).with(
          hash_including(
            template:  "studyrings_curriculum_v1",
            variables: hash_including(:topic, :member_background, :meeting_frequency, :purpose)
          )
        ).and_return(fixture_response)
        post generate_ring_path(ring)
      end

      it "creates one LearningCharter" do
        expect { post generate_ring_path(ring) }.to change(LearningCharter, :count).by(1)
      end

      it "creates six RingSessions" do
        expect { post generate_ring_path(ring) }.to change(RingSession, :count).by(6)
      end

      it "sets ring status to complete" do
        post generate_ring_path(ring)
        expect(ring.reload.status).to eq("complete")
      end

      it "redirects to the ring show page" do
        post generate_ring_path(ring)
        expect(response).to redirect_to(ring_path(ring))
      end
    end

    context "on GeminiService::TimeoutError" do
      before { gemini_raises(GeminiService::TimeoutError) }

      it "sets ring status to failed" do
        post generate_ring_path(ring)
        expect(ring.reload.status).to eq("failed")
      end

      it "renders the show page" do
        post generate_ring_path(ring)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "on GeminiService::BudgetExceededError" do
      before { gemini_raises(GeminiService::BudgetExceededError) }

      it "sets ring status to failed" do
        post generate_ring_path(ring)
        expect(ring.reload.status).to eq("failed")
      end
    end

    context "on GeminiService::GatekeeperError" do
      before { gemini_raises(GeminiService::GatekeeperError) }

      it "sets ring status to failed" do
        post generate_ring_path(ring)
        expect(ring.reload.status).to eq("failed")
      end
    end

    context "on JSON::ParserError (malformed response)" do
      before { allow(GeminiService).to receive(:generate).and_return("not valid json {{{{") }

      it "sets ring status to failed" do
        post generate_ring_path(ring)
        expect(ring.reload.status).to eq("failed")
      end
    end
  end

  # ── Access control ──────────────────────────────────────────────────────────

  describe "accessing another user's ring" do
    let(:other_ring) { create(:ring, user: other_user) }
    before { sign_in_as(user) }

    it "returns 404 for GET /rings/:id" do
      get ring_path(other_ring)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for DELETE /rings/:id" do
      delete ring_path(other_ring)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for POST /rings/:id/generate" do
      post generate_ring_path(other_ring)
      expect(response).to have_http_status(:not_found)
    end
  end

  # ── Destroy ─────────────────────────────────────────────────────────────────

  describe "DELETE /rings/:id" do
    before { sign_in_as(user) }

    it "destroys the ring" do
      ring
      expect { delete ring_path(ring) }.to change(Ring, :count).by(-1)
    end

    it "redirects to rings_path" do
      delete ring_path(ring)
      expect(response).to redirect_to(rings_path)
    end

    it "destroys the associated charter and sessions" do
      charter = create(:learning_charter, ring: ring)
      (1..3).each { |n| create(:ring_session, learning_charter: charter, week_number: n) }
      expect { delete ring_path(ring) }.to change(LearningCharter, :count).by(-1)
                                       .and change(RingSession, :count).by(-3)
    end
  end
end
