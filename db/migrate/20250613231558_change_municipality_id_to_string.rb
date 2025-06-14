class ChangeMunicipalityIdToString < ActiveRecord::Migration[8.0]
  def change
    change_column :representatives, :municipality_id, :string
  end
end 