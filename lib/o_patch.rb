module OPatch
  require 'o_patch/patcher'

  def self.patch(entity, attributes, &block)
    Patcher.patch(entity, attributes, &block)
  end
end
