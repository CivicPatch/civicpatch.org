class ModifyRepresentativesColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :representatives, :phone_number
    remove_column :representatives, :email
    remove_column :representatives, :website_url
    remove_column :representatives, :position

    add_column :representatives, :data, :jsonb, default: {}, null: false
  end
end
