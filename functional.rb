class Functional < Base
  class << self

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

    def rank_order(agent)
      beliefs = agent.belief_set

      if beliefs.has_key? 'calculateRankOrder'
        argument = only_arg beliefs, 'calculateRankOrder'
        currentTimeStamp = only_arg beliefs, 'currentTimeStamp'

        possible_agents = Array.new

        puts "RANK ARG: #{argument} - #{agent.id}"

        # Extremly simplified version: All in direct range, by id (due to broken comm data and complex system)
        # TODO: To test properly, add at least memberData:attendanceLevel to let an agent resign from this role
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

    def coalition_situations(agent)
      # To find situations on coalition level and averaged data

      # DELAYED: Simulation provides no data to infer situations
    end

    def coalition_events(agent)
      # To detect events on coalition level

      # DELAYED: Simulation provides no data to infer events
    end

  end
end