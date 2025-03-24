class CreatePlaceRepresentatives < ActiveRecord::Migration[8.0]
  def change
    create_table :place_representatives do |t|
      t.string :place_name, null: false
      t.references :representative, null: false, foreign_key: true

      t.timestamps
    end

    add_index :place_representatives, [:place_name, :representative_id], unique: true
  end
end
