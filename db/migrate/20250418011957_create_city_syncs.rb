class CreateCitySyncs < ActiveRecord::Migration[8.0]
  def change
    create_table :city_syncs do |t|
      t.string :state
      t.string :city_name
      t.string :gnis
      t.string :meta_hash

      t.timestamps
    end
  end
end
