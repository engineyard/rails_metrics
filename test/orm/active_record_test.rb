require 'test_helper'

class ActiveRecordTest < ActiveSupport::TestCase
  setup do
    Metric.delete_all
  end

  test "does not store queries other than SELECT, INSERT, UPDATE and DELETE" do
    instrument "test.event" do
      User.connection.send(:select, "SHOW tables;")
    end
    wait
    assert_equal 2, Metric.all.count # one for test.event and other for rack.request
  end

  test "serializes payload" do
    metric = Metric.new
    metric.configure(["metric", Time.now, Time.now, "id", {:foo => :bar}])
    metric.save!
    assert_equal Hash[:foo => :bar], metric.payload 
  end

  test "is invalid when name is blank" do
    metric = Metric.new
    assert metric.invalid?
    assert "can't be blank", metric.errors["name"].join
  end

  test "is invalid when started_at is blank" do
    metric = Metric.new
    assert metric.invalid?
    assert "can't be blank", metric.errors["started_at"].join
  end

  test "is invalid when duration is blank" do
    metric = Metric.new
    assert metric.invalid?
    assert "can't be blank", metric.errors["duration"].join
  end

  test "responds to all required named scopes" do
    [ :by_name, :by_request_id, :latest,
      :earliest, :slowest, :fastest, :requests ].each do |method|
      assert_respond_to Metric, method
    end
  end
end