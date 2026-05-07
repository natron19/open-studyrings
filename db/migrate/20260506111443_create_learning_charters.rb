class CreateLearningCharters < ActiveRecord::Migration[8.1]
  def change
    create_table :learning_charters, id: :uuid do |t|
      t.references :ring,               null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.text       :focus_statement
      t.text       :learning_goals
      t.text       :success_indicators
      t.text       :inquiry_framework
      t.text       :invite_suggestions
      t.text       :artifact_template
      t.text       :gemini_raw,         null: false
      t.timestamps                      null: false
    end

  end
end
