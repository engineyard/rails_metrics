require File.expand_path('test_helper', File.dirname(__FILE__))

class StoreTest < ActiveSupport::TestCase
  def sample_args
    time = Time.now
    ["rails_metrics.example", time, time + 10, "i" * 20, { :some => :info }]
  end

  # We need to mute RailsMetrics, otherwise we get Sqlite3 database lock errors
  def store!(args=sample_args)
    RailsMetrics.mute! do
      Metric.new.store!(args)
    end
  end

  setup do
    RailsMetrics::PayloadParser.add "rails_metrics.example"
  end

  teardown do
    RailsMetrics::PayloadParser.delete "rails_metrics.example"
  end

  test "sets the RailsMetrics.store when included" do
    swap RailsMetrics, :store => nil do
      klass = Class.new
      klass.send :include, RailsMetrics::Store
      assert_equal klass, RailsMetrics.store
    end
  end

  test "sets the name" do
    assert_equal "rails_metrics.example", store!.name
  end

  test "sets the duration" do
    assert_equal 10000, store!.duration
  end

  test "sets started at" do
    assert_kind_of Time, store!.started_at
  end

  test "sets the instrumenter id" do
    assert_equal ("i" * 20), store!.instrumenter_id
  end

  test "sets the payload" do
    assert_equal Hash[:some => :info], store!.payload
  end

  test "saves the record" do
    RailsMetrics.mute! do
      assert_difference "Metric.count" do
        store!
      end
    end
  end

  test "raises an error if cannot be saved" do
    assert_raise ActiveRecord::RecordInvalid do
      store!([nil, Time.now, Time.now])
    end
  end
end