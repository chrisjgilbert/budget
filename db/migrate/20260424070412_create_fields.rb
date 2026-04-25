class CreateFields < ActiveRecord::Migration[8.1]
  def change
    create_table :fields do |t|
      t.references :month, null: false, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.string :section, null: false
      t.string :behavior, null: false
      t.boolean :reset_on_new, null: false, default: false
      t.decimal :value, precision: 12, scale: 2, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :fields, [ :month_id, :key ], unique: true
  end
end
