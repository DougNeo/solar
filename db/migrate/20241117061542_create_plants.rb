class CreatePlants < ActiveRecord::Migration[8.0]
  def change
    create_table :plants do |t|
      t.integer :plant_id
      t.string :name
      t.decimal :latitude
      t.decimal :longitude
      t.string :address
      t.float :installed_capacity
      t.datetime :start_operating_time

      t.timestamps
    end
  end
end
