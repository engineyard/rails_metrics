class CreateMetrics < ActiveRecord::Migration
  def self.up
    create_table :metrics do |t|
      t.string :name
      t.integer :duration
      t.integer :instrumenter_id
      t.text :payload
      t.datetime :started_at
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :metrics
  end
end
