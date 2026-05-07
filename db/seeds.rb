# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_create_by!(name: "health_ping") do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
end

puts "Seeded: health_ping AI template"

AiTemplate.find_or_create_by!(name: "studyrings_curriculum_v1") do |t|
  t.description       = "Generates a complete O.R.B.I.T. learning charter and 6-session curriculum for a peer learning ring, structured to climb Bloom's Taxonomy from Week 1 to Week 6."
  t.model             = "gemini-2.5-flash"
  t.max_output_tokens = 3000
  t.temperature       = 0.6

  t.system_prompt = <<~PROMPT
    You are an expert peer learning facilitator who designs curricula for self-organized
    study groups called "rings". A ring is 4 to 8 peers who meet to learn a topic
    together with no instructor.

    You produce curricula in the O.R.B.I.T. framework: Origin, Rhythm, Build, Invite,
    Transform. The framework treats learning as a cycle that returns rather than a line
    that ends. Origin defines focus and goals. Rhythm sets the structure of sessions
    and the 6-session arc. Build provides an inquiry framework the ring can apply in
    any session. Invite suggests external voices for weeks 4 and 5. Transform names
    the artifact the ring will produce by week 6.

    Your six sessions must climb Bloom's Taxonomy across the weeks:
    - Week 1: Remember and Understand (orientation, definitions, foundational reading)
    - Week 2: Understand and Apply (working with concepts, first practice)
    - Week 3: Apply and Analyze (deeper practice, breaking concepts apart)
    - Week 4: Analyze and Evaluate (critique, comparison, often with an outside voice)
    - Week 5: Evaluate and Create (synthesis with an outside voice)
    - Week 6: Create (the ring produces its artifact)

    You must respect member background:
    - "beginner": more reading, gentler analytic questions, foundational resources
    - "mixed": variety, with at least one resource accessible to beginners and at least one stretch resource each week
    - "experienced": skip orientation, assume vocabulary, push to evaluate and create earlier

    You must respect meeting frequency:
    - "weekly": tighter preparation expectations, smaller resource list per week
    - "biweekly": more preparation between sessions, larger resource list per week

    You produce inquiry questions, not lectures. Sessions are facilitated by peers, not
    taught. Resources are starting points for the ring's own collection, not required
    texts. The artifact is something the ring chooses to make together by week 6.

    You output ONLY valid JSON matching the schema provided. No prose before or after.
    No markdown code fences. No explanations. Just the JSON object.
  PROMPT

  t.user_prompt_template = <<~PROMPT
    Generate a complete O.R.B.I.T. learning curriculum for a peer learning ring.

    Inputs:
    - Topic: {{topic}}
    - Member background: {{member_background}}
    - Meeting frequency: {{meeting_frequency}}
    - Purpose: {{purpose}}

    Return a single JSON object with this exact shape:

    {
      "focus_statement": "<one paragraph naming what this ring is studying and why>",
      "learning_goals": [
        "<goal 1, stated as an outcome>",
        "<goal 2, stated as an outcome>",
        "<goal 3, stated as an outcome>"
      ],
      "success_indicators": [
        "<indicator 1>",
        "<indicator 2>",
        "<indicator 3>"
      ],
      "inquiry_framework": "<a short framework specific to the topic that the ring can apply in any session to go deeper>",
      "invite_suggestions": "<2 to 3 sentences on the kinds of guest perspectives or external voices to bring in during weeks 4 and 5>",
      "artifact_template": "<a description of one artifact the ring will produce by week 6>",
      "sessions": [
        {
          "week_number": 1,
          "guiding_question": "<one question that orbits the week's Bloom level>",
          "resources": ["<resource 1>", "<resource 2>"],
          "discussion_prompts": ["<prompt 1>", "<prompt 2>", "<prompt 3>"],
          "inquiry_activity": "<one collaborative activity description>"
        },
        { "week_number": 2 },
        { "week_number": 3 },
        { "week_number": 4 },
        { "week_number": 5 },
        { "week_number": 6 }
      ]
    }

    The "sessions" array must contain exactly 6 objects, in week_number order from 1 to 6.
  PROMPT

  t.notes = <<~NOTES
    The Bloom's progression is enforced by the system prompt; Gemini does not reason
    about it. Watch for: (1) Week 6 producing another reading list instead of an
    artifact — tighten the artifact_template instruction if so. (2) Discussion prompts
    collapsing into closed yes/no questions for "beginner" rings. (3) Invite suggestions
    becoming generic ("invite an expert") — push toward specific perspective types.
    (4) JSON parse failures from trailing commentary — the "no prose before or after"
    instruction usually holds at temperature 0.6 but is not guaranteed. The controller
    catches JSON::ParserError and treats it as a GeminiError.
  NOTES
end

puts "Seeded: studyrings_curriculum_v1 AI template"

# Example ring for the demo user
demo_user = User.find_by!(email: "demo@example.com")

Ring.find_or_create_by!(user: demo_user, topic: "Network theory and how communities actually organize") do |r|
  r.member_background  = "mixed"
  r.meeting_frequency  = "biweekly"
  r.purpose            = "Three of us keep arguing about whether 'community' has any concrete meaning, and we want to read together until we have a useful answer."
  r.status             = "draft"
end

puts "Seeded: example ring for demo user"
