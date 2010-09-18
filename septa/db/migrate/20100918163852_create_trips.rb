class CreateTrips < ActiveRecord::Migration
  def self.up
    create_table :trips do |t|
      t.string :route_id
      t.string :service_id
      t.string :trip_id
      t.string :trip_headsign
      t.integer :block_id
      t.integer :trip_short_name
      t.string :shape_id

      t.timestamps
    end
  end

  def self.down
    drop_table :trips
  end
end
