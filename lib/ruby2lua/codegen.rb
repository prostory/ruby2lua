module Ruby2Lua
  class Call
    def mangled_name

    end
  end

  class CodeGenVisitor < Visitor
    attr_accessor :str

    def initialize(str = nil, indent_len = 2)
      @str = str || ''
      @indent = 0
      @indent_len = indent_len
    end

    def visit_expressions(node)
      node.each do |child|
        indent
        child.accept self
        str << "\n"
      end
      false
    end

    def visit_block(node)
      visit_expressions node
    end

    def visit_nil_lit(node)
      str << 'nil'
    end

    def visit_number_lit(node)
      str << node.value.to_s
    end

    def visit_string_lit(node)
      str << '"'
      str << node.value.to_s
      str << '"'
    end

    def visit_quote(node)
      str << node.code
    end

    def visit_d_string(node)
      str << '"'
      str << node.values.first.to_s
      str << '"'
      node.values[1..-1].each do |value|
        str << '..'
        value.accept self
      end
      false
    end

    def visit_variable(node)
      str << node.name.to_s
    end

    def visit_instance_var(node)
      str << "self[\"#{node.name}\"]"
    end

    def visit_class_var(node)
      str << "self[\"#{node.name}\"]"
    end

    def visit_argument(node)
      str << node.name.to_s
    end

    def visit_const(node)
      if node.owner
        node.owner.accept self
        str << '.'
      end
      str << "#{node.name}"
      false
    end

    def visit_call(node)
      if node.obj
        node.obj.accept self
        str << ':'
      end
      str << "#{node.name}"
      str << '('
      node.args.each_with_index do |arg, idx|
        str << ', ' if idx > 0
        arg.accept self
      end
      str << ')'
      false
    end

    def visit_return(node)
      str << 'return '
      node.values.each_with_index do |value, idx|
        str << ', ' if idx > 0
        value.accept self
      end
      false
    end

    def visit_assign(node)
      str << 'local ' if node.target.class == Variable
      node.target.accept self
      str << ' = '
      node.value.accept self
      false
    end

    def visit_module_def(node)
      node.name.accept self
      str << ' = '
      str << 'Object:newclass('
      node.name.accept self
      str << ", \"#{node.name.name}\")\n"
      str << "local self = #{node.name.name}:class()\n"
      indent
      node.name.accept self
      str << " = self\n"
      node.body.accept self
      false
    end

    def visit_class_def(node)
      str << "do\n"
      with_indent do
        indent
        str << 'local '
        str << 'self, __base = '
        if node.superclass
          node.superclass.accept self
        else
          str << 'Object'
        end
        str << ':newclass('
        node.name.accept self
        str << ", \"#{node.name.name}\")\n"
        indent
        node.name.accept self
        str << " = self\n"
        node.body.accept self
      end
      indent
      str << 'end'
      false
    end

    def visit_def(node)
      str << 'function '
      str << "__base:" if node.owner
      str << "#{node.name}(#{node.args.map(&:name).join ', '})\n"
      if !node.body.last.is_a?(Return)
        if node.body.last.is_a?(Assign)
          node.body << Return.new(node.body.last.target)
        else
          node.body << Return.new(node.body.children.pop)
        end
      end
      with_indent do
        node.body.accept self
      end
      indent
      str << 'end'
      false
    end

    def visit_static_def(node)
      str << 'function '
      str << "#{node.owner.name}:" if node.owner
      str << "#{node.name}(#{node.args.map(&:name).join ', '})\n"
      if !node.body.last.is_a?(Return)
        if node.body.last.is_a?(Assign)
          node.body << Return.new(node.body.last.target)
        else
          node.body << Return.new(node.body.children.pop)
        end
      end
      with_indent do
        node.body.accept self
      end
      indent
      str << 'end'
      false
    end

    def with_indent
      @indent += 1
      yield
      @indent -= 1
    end

    def indent
      str << (' ' * @indent_len * @indent)
    end

    def to_s
      str.strip
    end
  end
end