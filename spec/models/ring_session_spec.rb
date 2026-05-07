require "rails_helper"

RSpec.describe RingSession, type: :model do
  subject(:session) { build(:ring_session) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(session).to be_valid
    end

    describe "week_number" do
      (1..6).each do |n|
        it "accepts #{n}" do
          session.week_number = n
          expect(session).to be_valid
        end
      end

      it "rejects 0" do
        session.week_number = 0
        expect(session).not_to be_valid
      end

      it "rejects 7" do
        session.week_number = 7
        expect(session).not_to be_valid
      end

      it "requires presence" do
        session.week_number = nil
        expect(session).not_to be_valid
      end

      it "enforces uniqueness scoped to learning_charter_id" do
        charter = create(:learning_charter)
        create(:ring_session, learning_charter: charter, week_number: 1)
        duplicate = build(:ring_session, learning_charter: charter, week_number: 1)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:week_number]).to be_present
      end

      it "allows the same week_number in different charters" do
        charter_a = create(:learning_charter)
        charter_b = create(:learning_charter)
        create(:ring_session, learning_charter: charter_a, week_number: 1)
        other = build(:ring_session, learning_charter: charter_b, week_number: 1)
        expect(other).to be_valid
      end
    end

    it "requires guiding_question" do
      session.guiding_question = ""
      expect(session).not_to be_valid
      expect(session.errors[:guiding_question]).to be_present
    end
  end

  describe "#resources_list" do
    it "splits on newlines into an array" do
      session.resources = "Book A\nBook B"
      expect(session.resources_list).to eq(["Book A", "Book B"])
    end

    it "filters blank lines" do
      session.resources = "Book A\n\nBook B"
      expect(session.resources_list).to eq(["Book A", "Book B"])
    end

    it "returns an empty array when nil" do
      session.resources = nil
      expect(session.resources_list).to eq([])
    end
  end

  describe "#discussion_prompts_list" do
    it "splits on newlines into an array" do
      session.discussion_prompts = "Q1\nQ2\nQ3"
      expect(session.discussion_prompts_list).to eq(["Q1", "Q2", "Q3"])
    end

    it "filters blank lines" do
      session.discussion_prompts = "Q1\n\nQ2"
      expect(session.discussion_prompts_list).to eq(["Q1", "Q2"])
    end

    it "returns an empty array when nil" do
      session.discussion_prompts = nil
      expect(session.discussion_prompts_list).to eq([])
    end
  end
end
