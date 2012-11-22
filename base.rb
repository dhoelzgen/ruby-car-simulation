class Base

  def log(msg)
    puts "#{self.class.name}: #{msg}"
  end

  def debug(msg)
    puts "#{self.class.name}: #{msg}" if DEBUG_MSGS
  end

  class << self
    def only_arg(beliefs, name)
      return beliefs[name][0][0]
    end

    def args(beliefs, name)
      return beliefs[name][0]
    end
  end
end