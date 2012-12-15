ELP_WORLD = "dlvc/world.dlvc"
ELP_REPRESENTANT = "dlvc/representant.dlvc"
ELP_BASESTATION = "dlvc/basestation.dlvc"

class Agent < Base

  attr_reader :id

  # Initializes the agent with a set of initial individual beliefs
  # Adds initial information about other agents in range
  def initialize(id, agents)
    @id = id
    @current_belief_set = Hash.new

    # Create tmp file
    File.open(world_file, 'w+') do |tmp|
      tmp.puts("car(car#{id}).")
      tmp.puts("self(car#{id}).")
      tmp.puts("coalitionRankOrder(#{0},[car#{id}]).")
      agents.each do |other|
        tmp.puts("car(car#{other}).")
      end
    end
  end

  # Adds sensor data to the agents beliefs, given a timestamp
  def perceive(timestamp, data)
    File.open(world_file, 'a') do |tmp|
      data.each do |type, value|
        tmp.puts "sensorData(#{timestamp},#{type},#{value})."
      end
    end
  end

  # Adds communication possibilities to the agents beliefs, given a timestamp
  def add_in_range(timestamp, data, all)
    File.open(world_file, 'a') do |tmp|
      tmp.puts "withinDirectRange(#{timestamp},[#{data.map{|e| "car#{e}"}.join(',')}])."

      # All agents are in indirect comm range
      tmp.puts "withinCommRange(#{timestamp},[#{all.reject{|id| id == self.id}.map{|id| "car#{id}"}.join(',')}])."
    end
  end

  # Adds information to the agents beliefs, given a predicate name and its arguments
  def add_belief(name, args)
    File.open(world_file, 'a') do |tmp|
      tmp.puts "#{name}(#{args})."
    end
  end

  # Adds feedback about performed actions to the agents beliefs
  def add_performed_action_to_view(action, target)
    target_view = (target == 'base' ? view_basestation_file : view_agent_file(target))

    File.open(target_view, 'a') do |tmp|
      tmp.puts "#{action}."
    end
  end

  # Uses the solver to recalculate the current beliefset of the agent
  def update_belief_set!
    @current_belief_set = Solver.get ELP_WORLD, world_file
  end

  # Returns the current beliefset, can be used by other components
  def belief_set
    return @current_belief_set
  end

  # Returns alls predicated in the current beliefset that are intentions
  def intentions
    intentions = Hash.new
    belief_set.each { |name, args| (intentions[name] = args ) if (%w"sendInfo sendRequest sendAnswer".include? name) }
    return intentions
  end

  # Performs potential actions against basestation view
  def check_potential(action)
    fill_testfile(action)
    transfer_to_testfile('currentTimeStamp', 'self', 'currentCoalitionSize')
    result = Solver.get ELP_BASESTATION, view_basestation_file, test_file
    return result.any?
  end

  # Checks for real actions
  def check_real(action, target)
    target_elp = (target == 'base' ? ELP_BASESTATION : ELP_REPRESENTANT)
    target_view = (target == 'base' ? view_basestation_file : view_agent_file(target))

    fill_testfile(action)
    transfer_to_testfile('currentTimeStamp', 'self', 'currentCoalitionSize')
    result = Solver.get target_elp, target_view, test_file
    return result.any?
  end

  protected

  def fill_testfile(*actions)
    File.open(test_file, 'w+') do |tmp|
      actions.each do |action|
        tmp.puts "#{action}."
      end
    end
  end

  def transfer_to_testfile(*names)
    File.open(test_file, 'a') do |tmp|
      names.each do |name|
        tmp.puts "#{name}(#{belief_set[name][0][0]})." if belief_set.has_key? name
      end
    end
  end

  def world_file
    return "tmp/world_#{@id}.dlvc"
  end

  def view_basestation_file
    return "tmp/view_#{@id}_basestation.dlvc"
  end

  def view_agent_file(other)
    return "tmp/view_#{@id}_#{other}.dlvc"
  end

  def test_file
    return "tmp/test_#{@id}.dlvc"
  end

  def ectract_intention(name)
    return belief_set[name] if belief_set.has_key?(name)
  end
end