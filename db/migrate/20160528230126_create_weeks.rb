class CreateWeeks < ActiveRecord::Migration[5.0]
  def change
    create_table :weeks do |t|
      t.string :week_no, null: false, unique: true
      t.jsonb :days, null: false
      t.timestamps
    end
  end
end
