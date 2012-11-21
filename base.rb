class Base

  def log(msg)
    puts "#{self.class.name}: #{msg}"
  end

  def debug(msg)
    puts "#{self.class.name}: #{msg}" if DEBUG_MSGS
  end
end