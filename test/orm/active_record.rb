require 'test_helper'

class ActiveRecordTest < ActiveSupport::TestCase
  test "does not store own queries as notifications" do
    Metric.all
    wait
    assert Metric.all.empty?
  end

  test "does not store queries other than SELECT, INSERT, UPDATE and DELETE" do
    User.connection.select "SHOW tables;"
    wait
    assert Metric.all.empty?
  end
end