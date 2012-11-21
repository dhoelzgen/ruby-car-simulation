class Functional < Base
  class << self

    def attendance_level(agent)
      beliefs = agent.belief_set

      if agent.check_potential "performPotentialRepresentantActions"
        agent.add_belief("attendanceLevel", "#{only_arg(beliefs, 'currentTimeStamp')},representant")
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
        possible_agents = Array.new

        # Extremly simplified version: All in direct range, by id (due to broken comm data and complex system)
        # TODO: To test properly, add at least memberData:attendanceLevel to let an agent resign from this role
        if beliefs.has_key? 'currentWithinDirectRange'
          agent_list = args(beliefs, 'currentWithinDirectRange')[1] + only_arg(beliefs, 'self')
          agent_list = agent_list.gsub('[','').gsub(']','').gsub('car','').split('').map{ |i| i.to_i }
          agent_list.sort!
          agent_list.map! {|a| "car#{a}" }

          agent.add_belief("coalitionRankOrder", "#{only_arg(beliefs, 'currentTimeStamp')},[#{agent_list.join(',')}]")
        end
      end
    end

    def coalition_situations(agent)
      # To find situations on coalition level and averaged data

    end

    def coalition_events(agent)
      # To detect events on coalition level

    end

    protected

    def only_arg(beliefs, name)
      return beliefs[name][0][0]
    end

    def args(beliefs, name)
      return beliefs[name][0]
    end
  end
end