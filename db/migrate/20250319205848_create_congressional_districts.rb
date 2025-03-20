class CreateCongressionalDistricts < ActiveRecord::Migration[8.0]
  def change
    create_table :congressional_districts do |t|
      t.geometry :boundaries, srid: 4326, geographic: true
      t.string :ocd_id

      t.timestamps
    end
  end
end
