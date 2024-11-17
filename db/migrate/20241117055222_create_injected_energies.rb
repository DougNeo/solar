class CreateInjectedEnergies < ActiveRecord::Migration[8.0]
  def change
    create_table :injected_energies do |t|
      t.date :date
      t.decimal :energy

      t.timestamps
    end
  end
end
