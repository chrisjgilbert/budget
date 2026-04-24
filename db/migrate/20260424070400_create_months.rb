class CreateMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :months do |t|
      t.integer :year, null: false
      t.integer :month, null: false

      t.timestamps
    end

    add_index :months, [ :year, :month ], unique: true
  end
end
