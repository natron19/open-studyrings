class CreateRingSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :ring_sessions, id: :uuid do |t|
      t.references :learning_charter, null: false, foreign_key: true, type: :uuid
      t.integer    :week_number,      null: false
      t.text       :guiding_question, null: false
      t.text       :resources
      t.text       :discussion_prompts
      t.text       :inquiry_activity
      t.timestamps                    null: false
    end

    add_index :ring_sessions, [:learning_charter_id, :week_number], unique: true
  end
end
