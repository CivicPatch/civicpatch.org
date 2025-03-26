class AddPlaceRefToRepresentative < ActiveRecord::Migration[8.0]
  def change
    change_table :representatives do |t|
      t.references :place
    end
  end
end
