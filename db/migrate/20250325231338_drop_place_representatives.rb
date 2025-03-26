class DropPlaceRepresentatives < ActiveRecord::Migration[8.0]
  def up
    drop_table :place_representatives do |t|
      t.string :place_name
      t.references :representative, foreign_key: true
      t.timestamps
    end
  end

  def down
    create_table :place_representatives do |t|
      t.string :place_name
      t.references :representative, foreign_key: true
      t.timestamps
    end
  end
end
