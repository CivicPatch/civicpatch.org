class RemoveCountyFromMunicipalities < ActiveRecord::Migration[7.1]
  def change
    remove_column :municipalities, :county, :string
  end
end 