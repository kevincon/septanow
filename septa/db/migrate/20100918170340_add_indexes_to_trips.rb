class AddIndexesToTrips < ActiveRecord::Migration
  def self.up
add_index :trips, :trip_id
add_index :trips, :block_id
  end

  def self.down
remove_index :trips, :trip_id
remove_index :trips, :block_id
  end
end
