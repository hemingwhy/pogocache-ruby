class Pogocache::Batch < Pogocache::Cache
  attr_reader :ptr

  def initialize(ptr)
    @ptr = ptr
  end
end
