class Base

  def log(msg)
    puts "#{self.class.name}: #{msg}"
  end

  def debug(msg)
    puts "#{self.class.name}: #{msg}" if DEBUG_MSGS
  end

  def self.log(msg)
    puts "#{msg}"
  end

  def self.debug(msg)
    puts "#{msg}" if DEBUG_MSGS
  end
end