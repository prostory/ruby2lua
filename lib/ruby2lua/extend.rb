class Module
  def simple_name
    name.gsub /^.*::/, ''
  end
end

class String
  def underscore
    self.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z\d])([A-Z])/, '\1_\2').
      tr('-', '_').
      downcase
  end

  def to_lines_with_no
    self.split(/\n/)
    no = 0
    str = ''
    while no < lines.size
      str << "#{no+1}\t#{lines[no]}"
      no += 1
    end
    str
  end
end

class Symbol
  def underscore
    to_s.underscore.to_sym
  end
end

class Array
  def self.from(obj)
    case obj
    when nil
      new
    when Array
      new obj
    else
      new [obj]
    end
  end
end