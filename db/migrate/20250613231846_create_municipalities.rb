class CreateMunicipalities < ActiveRecord::Migration[7.1]
  def up
    create_table :municipalities do |t|
      t.string :name
      t.string :geoid
      t.string :state
      t.string :county
      t.string :type
      t.string :ocd_ids, array: true
      t.geometry :geom, srid: 4326

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :municipalities, :geoid
    add_index :municipalities, :ocd_ids, using: 'gin'
  end

  def down
    drop_table :municipalities
  end
end
