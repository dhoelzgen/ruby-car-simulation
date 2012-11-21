PATH_CAN_DATA = "input/sensor_can.txt"
PATH_COM_DATA = "input/sensor_car2car.txt"

class Environment < Base

  def initialize
    debug "Loading simulation data"

    loadCanData()
    loadComData()

    debug "Initialized environment"
  end

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

  def loadComData
    @comData = Hash.new

    File.open(PATH_COM_DATA).each_line do |line|
      data = line.split("\t")
      next if data[0] == "SimTime"

      # Format: Time / Autoindex / Direct Communication
      @comData[data[0]] ||= {}
      @comData[data[0]][data[1]] = convert_can_data_to_system(data[2]).split(",")
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
end