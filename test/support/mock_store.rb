class MockStore
  attr_accessor :args

  def self.instances
    @instances ||= []
  end

  def initialize
    self.class.instances << self
  end

  def store!(args)
    @args = args
  end
end
