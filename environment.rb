require 'set'

PATH_CAN_DATA = "input/sensor_can.txt"
PATH_COM_DATA = "input/sensor_car2car.txt"

class Environment < Base

  # Initializes the environment and loads all data
  def initialize
    debug "Loading simulation data"

    loadCanData()
    loadComData()

    debug "Initialized environment"
  end

  # Data related stuff

  # Loads all sensor input data from file
  def loadCanData
    @canData = Hash.new

    File.open(PATH_CAN_DATA).each_line do |line|
      data = line.split("\t")
      next if data[0] == "SimTime"

      # Format: Time / Autoindex / Type / Value
      @canData[data[0]] ||= {}
      @canData[data[0]][data[1]] ||= {}
      @canData[data[0]][data[1]][convert_can_type_to_system(data[2])] = convert_can_data_to_system(data[3]).to_i

    end

    debug "Loaded sensor data"
  end

  # Loads all communication possibilities from file
  def loadComData
    @comData = Hash.new

    # Load direct communication targets from file
    File.open(PATH_COM_DATA).each_line do |line|
      # Warning: This is only generated every few steps per agent and thus not symmetric (as it should be)
      data = line.split("\t")
      next if data[0] == "SimTime"

      # Format: Time / Autoindex / Direct Communication
      @comData[data[0]] ||= Hash.new
      @comData[data[0]][data[1]] ||= Set.new

      targets = convert_can_data_to_system(data[2]).split(",")

      @comData[data[0]][data[1]].merge targets
    end

    debug "Repairing data"
    # Repair data: Direct communication targets should be symmetric
    @comData.each do |time, data|
      data.each do |car, targets|
        targets.each do |target|
          # Add car to target's targets if car can comunicate with target
          @comData[time][target] ||= last_com_for_car(target, time)
          @comData[time][target] << car
        end
      end
    end

    debug "Loaded communication data"
  end

  def can_data(step)
    return @canData[step]
  end

  def com_data(step)
    return @comData[step]
  end

  protected

  def convert_can_type_to_system(type)
    return :velocity if type == "CANvelocity"
    return :laneid if type == "CANlaneid"
    return type.to_sym
  end

  def convert_can_data_to_system(data)
    return "" unless data
    return data.gsub("\n", "")
  end

  def last_com_for_car(car, time)
    while time.to_i >= 0
      if @comData.has_key?(time)
        return @comData[time][car] if @comData[time].has_key?(car)
      end
      time = ((time.to_i) - 1).to_s
    end

    return Set.new
  end
end