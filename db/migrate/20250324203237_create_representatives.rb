class CreateRepresentatives < ActiveRecord::Migration[8.0]
  def change
    create_table :representatives do |t|
      t.string :name, null: false
      t.string :phone_number
      t.string :email
      t.string :website_url
      t.string :position

      t.timestamps
    end
  end
end
