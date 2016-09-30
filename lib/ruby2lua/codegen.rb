module Ruby2Lua
  class Scope
    attr_accessor :name
    attr_accessor :def
    attr_accessor :vars

    def initialize(name, a_def, vars)
      @name = name
      @def = a_def
      @vars = vars
    end

    def to_s
      name.to_s
    end
  end

  class TopScope < Scope
    def initialize
      @name = :_TOP
      @def = nil
      @vars = {}
    end
  end

  class CodeGenVisitor < Visitor
    attr_accessor :file

    def initialize(file = nil, indent_len = 2)
      @file = file || ''
      @indent = 0
      @indent_len = indent_len
      @top_scope = TopScope.new
      @scopes = [@top_scope]
    end

    def visit_block(node)
      with_indent {
        node.each do |child|
          indent
          child.accept self
          file << "\n"
        end
      }
      false
    end

    def visit_nil(node)
      file << 'nil'
    end

    def visit_lit(node)
      file << node.value.to_s
    end

    def visit_true(node)
      file << 'true'
    end

    def visit_false(node)
      file << 'false'
    end

    def visit_str(node)
      file << '"'
      file << node.value.to_s
      file << '"'
    end

    def visit_xstr(node)
      file << node.value.to_s
    end

    def visit_dstr(node)
      file << '"'
      file << node.string
      file << '"'
      node.values.each do |value|
        file << ' .. '
        value.accept self
      end
      false
    end

    def visit_lvar(node)
      file << node.name.to_s
    end

    def visit_ivar(node)
      file << "self[\"@#{node.name.to_s}\"]"
    end

    def visit_cvar(node)
      file << "self[\"@@#{node.name.to_s}\"]"
    end

    def visit_gvar(node)
      file << "_G[\"$#{node.name.to_s}\"]"
    end

    def visit_self(node)
      file << 'self'
    end

    def visit_const(node)
      file << scope.to_s
      file << '_'
      file << node.name.to_s
    end

    def visit_colon2(node)
      node.owner.accept self
      file << '_'
      file << node.name.to_s
      false
    end

    def visit_colon3(node)
      file << top_scope.to_s
      file << '_'
      file << node.name.to_s
    end

    def visit_call(node)
      if node.obj
        node.obj.accept self
        file << ':'
      end
      file << node.name.to_s
      file << '('
      node.args.each_with_index do |arg, idx|
        file << ', ' if idx > 0
        arg.accept self
      end
      file << ')'
      false
    end

    def visit_lasgn(node)
      unless scope.vars.has_key? node.target.name
        scope.vars[node.target.name] = true
        file << 'local '
      end
      node.target.accept self
      file << ' = '
      node.value.accept self
      false
    end

    def visit_iasgn(node)
      node.target.accept self
      file << ' = '
      node.value.accept self
      false
    end

    def visit_cvasgn(node)
      node.target.accept self
      file << ' = '
      node.value.accept self
      false
    end

    def visit_gasgn(node)
      node.target.accept self
      file << ' = '
      node.value.accept self
      false
    end

    def visit_cdecl(node)
      node.target.accept self
      file << ' = '
      node.value.accept self
      false
    end

    def visit_module(node)
      node.name.accept self
      file << " = {}\n"
      file << "do\n"
      with_new_scope(node.name.name, nil) do
        node.body.accept self
      end
      file << 'end'
      false
    end

    def visit_class(node)
      node.name.accept self
      file << " = {}\n"
      file << "do\n"
      with_new_scope(node.name.name, nil) do
        node.body.accept self
      end
      file << 'end'
      false
    end

    def with_new_scope(name, a_def)
      @scopes.push(Scope.new(name, a_def, {}))
      yield
      @scopes.pop
    end

    def top_scope
      @top_scope
    end

    def scope
      @scopes.last
    end

    def with_indent
      @indent += 1
      yield
      @indent -= 1
    end

    def indent
      file << (' ' * @indent_len * @indent)
    end

    def to_s
      file.strip
    end
  end
end