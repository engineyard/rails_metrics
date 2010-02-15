require 'test_helper'

class StoreTest < ActiveSupport::TestCase
  setup do
    RailsMetrics.set_store { MockStore }
    MockStore.instances.clear
  end

  def sample_args
    time = Time.now
    ["rails_metrics.example", time, time + 1, 1, { :some => :info }]
  end

  def store!(args=sample_args)
    metric = Metric.new
    metric.configure(args)
    metric
  end

  test "sets the name" do
    assert_equal "rails_metrics.example", store!.name
  end

  test "sets the duration" do
    assert_equal 1000000, store!.duration
    assert_equal 1000000, store!.duration_in_us
    assert_equal 1000, store!.duration_in_ms
  end

  test "sets started at" do
    assert_kind_of Time, store!.started_at
  end

  test "sets the payload" do
    assert_equal Hash[:some => :info], store!.payload
  end

  test "nested instrumentations are saved nested" do
    instrument "rails_metrics.parent" do
      instrument "rails_metrics.child" do
      end
    end

    instrument "rails_metrics.another"

    assert_equal 5, MockStore.instances.size
    child, parent, request, another, another_request = MockStore.instances

    assert_equal request.id, request.request_id
    assert_equal request.id, parent.request_id
    assert_equal request.id, parent.parent_id
    assert_equal request.id, child.request_id
    assert_equal parent.id, child.parent_id

    assert parent.parent_of?(child)
    assert child.child_of?(parent)

    assert !parent.parent_of?(another)
    assert !another.parent_of?(parent)
    assert !parent.child_of?(another)
    assert !another.child_of?(parent)
  end

  test "tree can be created from nested instrumentations" do
    instrument "rails_metrics.parent" do
      instrument "rails_metrics.child" do
      end
    end

    child, parent, request = MockStore.instances
    root = RailsMetrics.store.mount_tree(MockStore.instances)

    assert_equal "rails_metrics.child", child.name
    assert_equal "rails_metrics.parent", parent.name
    assert_equal "rack.request", request.name

    assert root.rack_request?
    assert [parent], root.children
    assert [child], parent.children
  end
end