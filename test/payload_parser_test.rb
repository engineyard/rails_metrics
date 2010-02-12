require 'test_helper'

class PayloadParserTest < ActiveSupport::TestCase
  setup do
    @_previous_parsers = RailsMetrics::PayloadParser.parsers.dup
  end

  teardown do
    RailsMetrics::PayloadParser.parsers.replace @_previous_parsers
  end

  delegate :add, :ignore, :filter, :to => RailsMetrics::PayloadParser

  test "a non registered parser returns payload as is" do
    assert_equal Hash[:some => :info], filter("rails_metrics.something", :some => :info)
  end

  test "a parser with hash converts into method calls" do
    add "rails_metrics.something", :except => [:foo, :bar]
    assert_equal Hash[:some => :info], filter("rails_metrics.something", :some => :info,
                                              :foo => :baz, :bar => :baz)
  end

  test "a parser with a block calls the block with payload" do
    add "rails_metrics.something" do |payload|
      assert_equal Hash[:some => :info], payload
      { :foo => :bar }
    end
    assert_equal Hash[:foo => :bar], filter("rails_metrics.something", :some => :info)
  end

  test "a parser can be ignored" do
    ignore "rails_metrics.something"
    assert_nil filter("rails_metrics.something", :some => :info)
  end
end