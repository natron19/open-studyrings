class RingsController < ApplicationController
  before_action :set_ring, only: [:show, :destroy, :generate]

  rate_limit to: 10, within: 1.minute, only: [:generate],
             with: -> { redirect_to ring_path(@ring), alert: "Please wait before generating again." }

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

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
    @charter  = @ring.learning_charter
    @sessions = @charter&.ring_sessions&.order(:week_number) || []
  end

  def destroy
    @ring.destroy
    redirect_to rings_path, notice: "Ring deleted."
  end

  def generate
    @ring.update!(status: "generating")

    response = GeminiService.generate(
      template:  "studyrings_curriculum_v1",
      variables: {
        topic:             @ring.topic,
        member_background: @ring.member_background,
        meeting_frequency: @ring.meeting_frequency,
        purpose:           @ring.purpose
      }
    )

    data     = JSON.parse(response, symbolize_names: true)
    sessions = data[:sessions]

    unless sessions.is_a?(Array) && sessions.length == 6
      raise GeminiService::GeminiError, "Expected 6 sessions, got #{sessions&.length || 0}"
    end

    ActiveRecord::Base.transaction do
      charter = @ring.create_learning_charter!(
        gemini_raw:          response,
        focus_statement:     data[:focus_statement],
        learning_goals:      Array(data[:learning_goals]).join("\n"),
        success_indicators:  Array(data[:success_indicators]).join("\n"),
        inquiry_framework:   data[:inquiry_framework],
        invite_suggestions:  data[:invite_suggestions],
        artifact_template:   data[:artifact_template]
      )

      sessions.each do |s|
        charter.ring_sessions.create!(
          week_number:        s[:week_number],
          guiding_question:   s[:guiding_question],
          resources:          Array(s[:resources]).join("\n"),
          discussion_prompts: Array(s[:discussion_prompts]).join("\n"),
          inquiry_activity:   s[:inquiry_activity]
        )
      end
    end

    @ring.update!(status: "complete")
    redirect_to ring_path(@ring), notice: "Your curriculum is ready."

  rescue JSON::ParserError
    @ring.update!(status: "failed")
    render :show, status: :unprocessable_entity

  rescue GeminiService::BudgetExceededError
    @ring.update!(status: "failed")
    render :show, status: :unprocessable_entity

  rescue GeminiService::GatekeeperError
    @ring.update!(status: "failed")
    render :show, status: :unprocessable_entity

  rescue GeminiService::TimeoutError
    @ring.update!(status: "failed")
    render :show, status: :unprocessable_entity

  rescue GeminiService::GeminiError
    @ring.update!(status: "failed")
    render :show, status: :unprocessable_entity
  end

  private

  def set_ring
    @ring = current_user.rings.find(params[:id])
  end

  def ring_params
    params.require(:ring).permit(:topic, :member_background, :meeting_frequency, :purpose)
  end
end
