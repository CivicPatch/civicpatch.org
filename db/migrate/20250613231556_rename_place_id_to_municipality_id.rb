class RenamePlaceIdToMunicipalityId < ActiveRecord::Migration[8.0]
  def change
    rename_column :representatives, :place_id, :municipality_id
  end
end
