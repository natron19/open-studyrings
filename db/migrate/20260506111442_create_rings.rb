class CreateRings < ActiveRecord::Migration[8.1]
  def change
    create_table :rings, id: :uuid do |t|
      t.references :user,              null: false, foreign_key: true, type: :uuid
      t.string     :topic,             null: false
      t.string     :member_background, null: false
      t.string     :meeting_frequency, null: false
      t.text       :purpose,           null: false
      t.string     :status,            null: false, default: "draft"
      t.timestamps                     null: false
    end

    add_index :rings, :status
  end
end
