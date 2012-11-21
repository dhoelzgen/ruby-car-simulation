require 'base'
require 'environment'
require 'agent'

class Simulation < Base
  def initialize
    @environment = Environment.new
  end
end