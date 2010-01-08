require 'test_helper'

RailsMetrics::PayloadParser.mattr_accessor :parsers

class PayloadParserTest < ActiveSupport::TestCase
  setup do
    @_previous_parsers = RailsMetrics::PayloadParser.parsers.dup
  end

  teardown do
    RailsMetrics::PayloadParser.parsers = @_previous_parsers
  end

  delegate :add, :delete, :filter, :to => RailsMetrics::PayloadParser

  test "a parser without parameters returns payload as is" do
    add "rails_metrics.something"
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

  test "a non registered parser simply returns nil" do
    assert_nil filter("rails_metrics.something", :some => :info)
  end

  test "a parser can be deleted" do
    add "rails_metrics.something"
    delete "rails_metrics.something"
    assert_nil filter("rails_metrics.something", :some => :info)
  end
end