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
      @canData[data[0]][data[1]] = { convertCanTypeToSystem(data[2]) => convertCanDataToSystem(data[3]) }
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
      @comData[data[0]][data[1]] = convertCanDataToSystem(data[2]).split(",")
    end

    debug "Loaded communication data"
  end


  protected

  def convertCanTypeToSystem(type)
    return :velocity if type == "CANvelocity"
    return :laneid if type == "CANlaneid"
    return type.to_sym
  end

  def convertCanDataToSystem(data)
    return "" unless data
    return data.gsub("\n", "")
  end
end