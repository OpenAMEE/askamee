class CreateSearches < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.string :string
      t.integer :count, :default => 0
      t.timestamps
    end
    add_index :searches, :string
  end
end
