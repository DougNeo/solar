class BuildSolarDashboard < ActiveRecord::Migration[8.1]
  def change
    change_column :plants, :plant_id, :string
    add_column :plants, :status, :string
    add_column :plants, :current_power_kw, :decimal, precision: 12, scale: 3
    add_column :plants, :daily_energy_kwh, :decimal, precision: 14, scale: 3
    add_column :plants, :total_energy_kwh, :decimal, precision: 16, scale: 3
    add_column :plants, :last_synced_at, :datetime
    add_column :plants, :metadata, :json, default: {}
    add_index :plants, :plant_id, unique: true

    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.datetime :last_login_at
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :devices do |t|
      t.references :plant, null: false, foreign_key: true
      t.string :serial, null: false
      t.string :name
      t.string :device_type
      t.string :status
      t.datetime :last_collected_at
      t.json :telemetry, default: {}
      t.timestamps
    end
    add_index :devices, :serial, unique: true

    create_table :energy_readings do |t|
      t.references :plant, null: false, foreign_key: true
      t.date :recorded_on, null: false
      t.decimal :generation_kwh, precision: 14, scale: 3
      t.decimal :power_kw, precision: 12, scale: 3
      t.json :metrics, default: {}
      t.timestamps
    end
    add_index :energy_readings, %i[plant_id recorded_on], unique: true

    create_table :alerts do |t|
      t.references :plant, null: false, foreign_key: true
      t.references :device, foreign_key: true
      t.string :external_id, null: false
      t.string :title
      t.string :severity
      t.string :status
      t.text :influence
      t.text :solution
      t.datetime :occurred_at
      t.datetime :resolved_at
      t.json :metadata, default: {}
      t.timestamps
    end
    add_index :alerts, :external_id, unique: true
  end
end
