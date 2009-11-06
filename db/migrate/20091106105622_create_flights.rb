class CreateFlights < ActiveRecord::Migration
  def self.up
    create_table :flights do |t|
      t.datetime :departs_at
      t.float :price
      t.string :from_airport
      t.string :to_airport

      t.timestamps
    end
  end

  def self.down
    drop_table :flights
  end
end
