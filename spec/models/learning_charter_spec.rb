require "rails_helper"

RSpec.describe LearningCharter, type: :model do
  subject(:charter) { build(:learning_charter, ring: create(:ring)) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(charter).to be_valid
    end

    it "requires gemini_raw" do
      charter.gemini_raw = ""
      expect(charter).not_to be_valid
      expect(charter.errors[:gemini_raw]).to be_present
    end

    it "requires ring_id" do
      charter.ring = nil
      expect(charter).not_to be_valid
    end

    it "enforces uniqueness on ring_id" do
      ring = create(:ring)
      create(:learning_charter, ring: ring)
      duplicate = build(:learning_charter, ring: ring)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ring_id]).to be_present
    end
  end

  describe "associations" do
    it "destroys ring_sessions when destroyed" do
      charter = create(:learning_charter)
      create(:ring_session, learning_charter: charter)
      expect { charter.destroy }.to change(RingSession, :count).by(-1)
    end
  end

  describe "#learning_goals_list" do
    it "splits on newlines into an array" do
      charter.learning_goals = "Goal A\nGoal B\nGoal C"
      expect(charter.learning_goals_list).to eq(["Goal A", "Goal B", "Goal C"])
    end

    it "filters blank lines" do
      charter.learning_goals = "Goal A\n\nGoal B"
      expect(charter.learning_goals_list).to eq(["Goal A", "Goal B"])
    end

    it "returns an empty array when nil" do
      charter.learning_goals = nil
      expect(charter.learning_goals_list).to eq([])
    end
  end

  describe "#success_indicators_list" do
    it "splits on newlines into an array" do
      charter.success_indicators = "Indicator 1\nIndicator 2"
      expect(charter.success_indicators_list).to eq(["Indicator 1", "Indicator 2"])
    end

    it "filters blank lines" do
      charter.success_indicators = "Indicator 1\n\nIndicator 2"
      expect(charter.success_indicators_list).to eq(["Indicator 1", "Indicator 2"])
    end

    it "returns an empty array when nil" do
      charter.success_indicators = nil
      expect(charter.success_indicators_list).to eq([])
    end
  end
end
