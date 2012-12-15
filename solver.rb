DLVC_COMMAND = "/usr/local/bin/dlv-complex -silent"

class Solver

  class << self

    # Calculates the answer set given an elp
    # Limited to process only one answer set
    # Result: { name => [[arg1,arg2, ...], ...], ...}
    def get(*file)
      file.reject! {|f| !File.exists? f }
      output = (%x(/usr/local/bin/dlv-complex -silent #{file.join(" ")})).gsub('{', '').gsub('}', '')
      answerset = Hash.new

      output.split(', ').each do |predicate|
        if match = predicate.match(/(.*)\((.*)\)/)
          answerset[match[1]] ||= Array.new

          bracket_level = 0
          arguments = match[2].each_char.map do |c|
            bracket_level += 1 if c == "["
            bracket_level -= 1 if c == "]"

            next ';' if c == "," and bracket_level > 0
            next c
          end.join

          answerset[match[1]] << arguments.split(',').map{ |arg| arg.gsub(";", ",") }
        else
          answerset[predicate] = true
        end
      end

      return answerset
    end

  end

end