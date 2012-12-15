require 'base'
require 'environment'
require 'functional'
require 'agent'
require 'solver'
require 'fileutils'

SIMULATION_STEPS_LIMIT = 80

class Simulation < Base

  # Initializes the simulation
  # Creates the temp directory for dlv input files
  # Initializes environment and empty agent list
  def initialize
    # Clean up
    FileUtils.rm Dir.glob('tmp/*')

    # Init
    @environment = Environment.new
    @agents = Hash.new

    @current_step = 0
  end

  # Starts the simulation loop
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
            agent(id).add_in_range(@current_step, data, @agents.keys)
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
        Functional.coalition_situations(agent)
      end

      update_beliefs!

      # Intention update and action selection
      @agents.each do |id, agent|
        process_intentions(agent)
      end

      # Clean
      @current_step += 1

    end
  end

  # Updates the current belief set of all agents currently present in the system
  def update_beliefs!
    @agents.each do |id, agent|
      agent.update_belief_set!
    end
  end

  # Processes the possible intentions
  # Identifies the selected speech act and selects real targets selected by placeholders
  def process_intentions(agent)
    intentions = agent.intentions
    return unless intentions.any?

    # Get possible targets
    communication_targtets = Hash.new

    agent.belief_set['communicationTarget'].each do |name, entity|
      communication_targtets[name] ||= Array.new
      communication_targtets[name] << entity
    end if agent.belief_set.has_key? 'communicationTarget'

    # Perform speechacts
    intentions.each do |speechact, informations|
      informations.each do |information|
        debug "Agent #{agent.id} #{speechact} to #{information[0]}: #{information[1]}/#{information[2]} #{information.length > 3 ? " - " + information[3] : ""}"

        receivers = [information[0]]

        if communication_targtets.has_key? receivers[0]
          receivers = communication_targtets[receivers[0]]
        end

        receivers.each do |receiver|
          perform(
            agent,
            receiver,
            speechact,
            information[1],
            information[2],
            (information.length > 3 ? information[3] : nil)
          )
        end

      end
    end
  end

  # Performs the acction according to secrecy preservation
  # Simulates action first, it is only performed if no secrets are violated
  def perform(agent, receiver, speechact, domain, type, value)
    return unless has_agent_with_name?(receiver) or (receiver == 'base')

    info = nil; feedback = nil
    info_args = ""; feedback_args = ""

    # DELAYED: Test if target is in range is problematic due to given data

    if speechact == 'sendInfo'
      info = 'receivedInfo'
      feedback = 'sentInfo'
    elsif speechact == 'sendRequest'
      info = 'receivedRequest'
      feedback = 'sentRequest'
    elsif speechact == 'sendAnswer'
      info = 'receivedAnswer'
      feedback = 'sentAnswer'
    else
      raise "Unknown speech act: #{speechact}"
    end

    if speechact == 'sendInfo' or speechact == 'sendAnswer'
      info_args = [@current_step, "car#{agent.id}", domain, type, value].join(',')
      feedback_args = [@current_step, receiver, domain, type, value].join(',')
    else
      info_args = [@current_step, "car#{agent.id}", domain, type].join(',')
      feedback_args = [@current_step, receiver, domain, type].join(',')
    end

    # Add feedback (in any case)
    agent.add_belief(feedback, feedback_args)

    # Test secrecy
    if agent.check_real "#{info}(#{info_args})", receiver
      # Adjust View
      agent.add_performed_action_to_view "#{info}(#{info_args})", receiver

      # Send information
      if receiver == 'base'
        # TODO: Collect all info for base station
        log "Base got info: #{info_args}"
      else
        @agents[receiver.gsub('car', '')].add_belief info, info_args
      end
    end

  end

  protected

  def has_agent?(id)
    return @agents.has_key?(id)
  end

  def has_agent_with_name?(id)
    return @agents.has_key?(id.gsub('car', ''))
  end

  def agent(id)
    return @agents[id]
  end

end