class CreateMetrics < ActiveRecord::Migration
  def self.up
    create_table :metrics do |t|
      t.string :name
      t.integer :request_id
      t.integer :parent_id
      t.integer :duration
      t.text :payload
      t.datetime :started_at
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :metrics
  end
end
