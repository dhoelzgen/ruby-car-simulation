class Functional < Base
  class << self

    # Calculates the agent's attendance level given its beliefs
    def attendance_level(agent)
      beliefs = agent.belief_set

      if agent.check_potential "performPotentialRepresentantActions"
        agent.add_belief("attendanceLevel", "#{only_arg(beliefs, 'currentTimeStamp')},representative")
      elsif agent.check_potential "performPotentialMemberActions"
        agent.add_belief("attendanceLevel", "#{only_arg(beliefs, 'currentTimeStamp')},member")
      else
        agent.add_belief("attendanceLevel", "#{only_arg(beliefs, 'currentTimeStamp')},none")
      end
    end


    # Calculates the current rank order of the agent's coalition given its beliefs
    def rank_order(agent)
      beliefs = agent.belief_set

      if beliefs.has_key? 'calculateRankOrder'
        argument = only_arg beliefs, 'calculateRankOrder'
        currentTimeStamp = only_arg beliefs, 'currentTimeStamp'

        possible_agents = Array.new

        # Extremly simplified version: All in direct range, by id (due to broken comm data and complex system)
        # DELAYED: Agent steps back from representative role, but simplification prevents proper rank order
        if beliefs.has_key? 'withinCommRange'
          agent_list = beliefs['withinCommRange'].each do |args|
            break args[1] if args[0] == currentTimeStamp
          end

          return unless agent_list.is_a? String # If not, there is no current data

          agent_list = agent_list.gsub('[','').gsub(']','').gsub('car','').split(',').map{ |i| i.to_i }
          agent_list << agent.id.to_i
          agent_list.sort!
          agent_list.map! {|a| "car#{a}" }

          agent.add_belief("coalitionRankOrder", "#{only_arg(beliefs, 'currentTimeStamp')},[#{agent_list.join(',')}]")
        end
      end
    end

    # Processes individual situations provided by other coalition members and identifies situations on coalition level
    def coalition_situations(agent)
      # To find situations on coalition level and averaged data

      # DELAYED: Real choice of situation not possible due to given data
      beliefs = agent.belief_set
      situations = Hash.new

      if beliefs.has_key?('inputSituation') && beliefs.has_key?('analyseCoalitionSituation')
        beliefs['inputSituation'].each do |args|
          situations[args[1]] ||= Hash.new
          situations[args[1]][args[2]] ||= 0
          situations[args[1]][args[2]] += 1
        end
      end

      situations.each do |type, values|
        values.each do |value, count|
          agent.add_belief("coalitionSituation", "#{only_arg(beliefs, 'currentTimeStamp')},#{type},#{value}")
        end
      end
    end

  end
end