require "rails_helper"

RSpec.describe Ring, type: :model do
  subject(:ring) { build(:ring) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(ring).to be_valid
    end

    describe "topic" do
      it "requires presence" do
        ring.topic = ""
        expect(ring).not_to be_valid
        expect(ring.errors[:topic]).to be_present
      end

      it "requires at least 5 characters" do
        ring.topic = "ab c"
        expect(ring).not_to be_valid
      end

      it "accepts exactly 5 characters" do
        ring.topic = "abcde"
        expect(ring).to be_valid
      end

      it "rejects more than 200 characters" do
        ring.topic = "a" * 201
        expect(ring).not_to be_valid
      end

      it "accepts exactly 200 characters" do
        ring.topic = "a" * 200
        expect(ring).to be_valid
      end
    end

    describe "member_background" do
      %w[beginner mixed experienced].each do |value|
        it "accepts '#{value}'" do
          ring.member_background = value
          expect(ring).to be_valid
        end
      end

      it "rejects an invalid value" do
        ring.member_background = "expert"
        expect(ring).not_to be_valid
      end
    end

    describe "meeting_frequency" do
      %w[weekly biweekly].each do |value|
        it "accepts '#{value}'" do
          ring.meeting_frequency = value
          expect(ring).to be_valid
        end
      end

      it "rejects an invalid value" do
        ring.meeting_frequency = "daily"
        expect(ring).not_to be_valid
      end
    end

    describe "purpose" do
      it "requires presence" do
        ring.purpose = ""
        expect(ring).not_to be_valid
      end

      it "requires at least 10 characters" do
        ring.purpose = "too short"
        expect(ring).not_to be_valid
      end

      it "accepts exactly 10 characters" do
        ring.purpose = "a" * 10
        expect(ring).to be_valid
      end

      it "rejects more than 500 characters" do
        ring.purpose = "a" * 501
        expect(ring).not_to be_valid
      end

      it "accepts exactly 500 characters" do
        ring.purpose = "a" * 500
        expect(ring).to be_valid
      end
    end

    describe "status" do
      %w[draft generating complete failed].each do |value|
        it "accepts '#{value}'" do
          ring.status = value
          expect(ring).to be_valid
        end
      end

      it "rejects an invalid value" do
        ring.status = "pending"
        expect(ring).not_to be_valid
      end

      it "defaults to 'draft'" do
        expect(Ring.new.status).to eq("draft")
      end
    end
  end

  describe "associations" do
    it "belongs to a user" do
      ring = build(:ring, user: nil)
      expect(ring).not_to be_valid
    end

    it "has one learning charter" do
      expect(Ring.reflect_on_association(:learning_charter).macro).to eq(:has_one)
    end

    it "destroys the learning charter when destroyed" do
      ring = create(:ring)
      charter = create(:learning_charter, ring: ring)
      expect { ring.destroy }.to change(LearningCharter, :count).by(-1)
      expect(LearningCharter.exists?(charter.id)).to be false
    end

    it "destroys ring sessions when the ring is destroyed" do
      ring = create(:ring)
      charter = create(:learning_charter, ring: ring)
      session = create(:ring_session, learning_charter: charter)
      expect { ring.destroy }.to change(RingSession, :count).by(-1)
      expect(RingSession.exists?(session.id)).to be false
    end
  end

  describe ".ordered" do
    it "returns rings newest first" do
      older = create(:ring, created_at: 2.days.ago)
      newer = create(:ring, created_at: 1.day.ago)
      expect(Ring.ordered.first).to eq(newer)
      expect(Ring.ordered.last).to eq(older)
    end
  end
end
