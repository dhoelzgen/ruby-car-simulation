DLVC_COMMAND = "/usr/local/bin/dlv-complex -silent"

class Solver

  class << self

    # Result: { name => [[arg1,arg2, ...], ...], ...}
    def get(*file)
      file.reject! {|f| !File.exists? f }
      output = (%x(/usr/local/bin/dlv-complex -silent #{file.join(" ")})).gsub('{', '').gsub('}', '')
      answerset = Hash.new

      output.split(', ').each do |predicate|
        if match = predicate.match(/(.*)\((.*)\)/)
          answerset[match[1]] ||= Array.new
          answerset[match[1]] << match[2].split(',')
        else
          answerset[predicate] = true
        end
      end

      return answerset
    end

  end

end