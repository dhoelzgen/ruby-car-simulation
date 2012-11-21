require 'base'
require 'environment'
require 'functional'
require 'agent'
require 'solver'
require 'fileutils'

SIMULATION_STEPS_LIMIT = 10

class Simulation < Base

  def initialize
    # Clean up
    FileUtils.rm Dir.glob('tmp/*')

    # Init
    @environment = Environment.new
    @agents = Hash.new

    @current_step = 0
  end

  def run!
    while @current_step < SIMULATION_STEPS_LIMIT

      # Sensor data
      if can_data = @environment.can_data(@current_step.to_s)
        can_data.each do |id, data|
          unless has_agent?(id)
            @agents[id] = Agent.new(id, @agents.keys)

            @agents.each do |other_id, value|
              next if other_id == id
              value.add_belief('car', "car#{id}")
            end
          end

          agent(id).perceive(@current_step, data)
        end
      end

      if com_data = @environment.com_data(@current_step.to_s)
        com_data.each do |id, data|
          if has_agent?(id)
            agent(id).add_in_range(@current_step, data)
          end
        end
      end

      # Next timstamp
      @agents.each do |id, agent|
        agent.add_belief('timeStamp', @current_step)
      end

      update_beliefs!

      # Functional components
      @agents.each do |id, agent|
        Functional.attendance_level(agent)
        Functional.rank_order(agent)
      end

      update_beliefs!

      # Intention update
      @agents.each do |id, agent|
        pp agent.intentions
      end

      # Action selection

      # Clean
      @current_step += 1

    end
  end

  def update_beliefs!
    @agents.each do |id, agent|
      agent.update_belief_set!
    end
  end

  protected

  def has_agent?(id)
    return @agents.has_key?(id)
  end

  def agent(id)
    return @agents[id]
  end

end