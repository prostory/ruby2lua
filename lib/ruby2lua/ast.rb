require_relative 'extend'

module Ruby2Lua
  class Visitor
  end

  class ASTNode
    attr_accessor :location
    attr_accessor :sequence

    def self.inherited(klass)
      name = klass.simple_name.underscore
      klass.class_eval %Q(
	        def accept(visitor)
	          if visitor.visit_#{name} self
	            accept_children visitor
	          end
	          visitor.end_visit_#{name} self
	        end
	      )
      Visitor.class_eval %Q(
	        def visit_#{name}(node)
	          true
	        end

	        def end_visit_#{name}(node)
	        end
	      )
    end

    def accept_children(visitor)

    end

    def simple_clone
      self.class.new
    end

    def clone
      node = simple_clone
      node.location = location
      node.sequence = sequence
      node
    end
  end

  class Expressions < ASTNode
    include Enumerable

    attr_accessor :children

    def self.from(obj)
      case obj
      when nil
        new
      when Array
        new obj
      when Expressions, Do
        new obj.children
      else
        new [obj]
      end
    end

    def initialize(expressions = [])
      @children = expressions
    end

    def each(&block)
      children.each(&block)
    end

    def [](i)
      children[i]
    end

    def <<(child)
      children << child
    end

    def last
      children.last
    end

    def any?
      children.any?
    end

    def accept_children(visitor)
      children.each { |child| child.accept(visitor) }
    end

    def ==(other)
      other.class == self.class && other.children == children
    end

    def to_s
      "(#{children.join ' '})"
    end

    def simple_clone
      self.class.new children.map(&:clone)
    end
  end

  class Block < Expressions
  end

  class Lit < ASTNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def to_s
      @value.to_s
    end

    def ==(other)
      other.class == self.class && other.value == value
    end

    def simple_clone
      self.class.new value
    end
  end

  class NilLit < ASTNode
  end

  class NumberLit < Lit
  end

  class StringLit < Lit
    def initialize(value)
      @value = value.to_s
    end
  end

  class Quote < ASTNode
    attr_accessor :code

    def initialize(code)
      @code = code.to_s
    end

    def to_s
      @code
    end

    def ==(other)
      other.class == self.class && other.code == code
    end

    def simple_clone
      self.class.new code
    end
  end

  class DString < ASTNode
    attr_accessor :values

    def initialize(values = [])
      @values = Array.from values
    end

    def accept_children(visitor)
      values.each {|value| value.accept visitor}
    end

    def to_s
      "(return #{value.join ' '})"
    end

    def ==(other)
      other.class == self.class && other.values == values
    end

    def simple_clone
      self.class.new values
    end
  end

  class Variable < ASTNode
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def to_s
      @name.to_s
    end

    def ==(other)
      other.class == self.class && other.name == name
    end

    def simple_clone
      self.class.new name
    end
  end

  class InstanceVar < Variable
  end

  class ClassVar < Variable
  end

  class Argument < Variable
  end

  class Const < ASTNode
    attr_accessor :name
    attr_accessor :owner

    def initialize(name, owner = nil)
      @name = name
      @owner = owner
    end

    def accept_children(visitor)
      owner.accept visitor if owner
    end

    def ==(other)
      other.class == self.class && other.name == name &&
        other.owner == owner
    end

    def to_s
      str = owner ? "#{owner}:" : ''
      str << name.to_s
    end

    def simple_clone
      self.class.new name, owner.clone
    end
  end

  class Call < ASTNode
    attr_accessor :name
    attr_accessor :args
    attr_accessor :obj

    def initialize(name, args = [], obj = nil)
      @name = name
      @args = Array.from args
      @obj = obj
    end

    def accept_children(visitor)
      args.each { |arg| arg.accept(visitor) }
      obj.accept visitor if obj
    end

    def ==(other)
      other.class == self.class && other.name == name &&
        other.args == args && other.obj == obj
    end

    def to_s
      str = '('
      str << "#{obj}:" if obj
      str << name.to_s
      str << " #{args.join(' ')}" if args.any?
      str << ')'
    end

    def simple_clone
      self.class.new name, args, obj
    end
  end

  class Return < ASTNode
    attr_accessor :values

    def initialize(values = [])
      @values = Array.from values
    end

    def accept_children(visitor)
      values.each {|value| value.accept visitor}
    end

    def to_s
      "(return #{value.join ' '})"
    end

    def ==(other)
      other.class == self.class && other.values == values
    end

    def simple_clone
      self.class.new values
    end
  end

  class Assign < ASTNode
    attr_accessor :target
    attr_accessor :value

    def initialize(target, value)
      @target = target
      @value = value
    end

    def accept_children(visitor)
      target.accept visitor
      value.accept visitor
    end

    def to_s
      "(set #{target} #{value})"
    end

    def ==(other)
      other.class == self.class && other.target == target &&
        other.value == value
    end

    def simple_clone
      self.class.new target, value
    end
  end

  class ModuleDef < ASTNode
    attr_accessor :name
    attr_accessor :body

    def initialize(name, body = [])
      @name = name
      body.each {|child| child.owner = name if child.respond_to?(:owner) && child.owner.nil? }
      @body = Expressions.from body
    end

    def accept_children(visitor)
      name.accept visitor
      body.accept visitor
    end

    def ==(other)
      other.class == self.class && other.name == name &&
        other.body = body
    end

    def to_s
      str = '(module '
      str << name.to_s
      str << " #{body}" if body.any?
      str << ')'
      str
    end

    def simple_clone
      self.class.new name, body
    end
  end

  class ClassDef < ModuleDef
    attr_accessor :superclass

    def initialize(name, body = [], superclass = nil)
      super(name, body)
      @superclass = superclass
    end

    def accept_children(visitor)
      super visitor
      superclass.accept visitor if superclass
    end

    def ==(other)
      super && other.superclass == superclass
    end

    def to_s
      str = '(class '
      str << name.to_s
      str << " extend #{superclass}" if superclass
      str << " #{body}" if body.any?
      str << ')'
      str
    end

    def simple_clone
      self.class.new name, body, superclass
    end
  end

  class Def < ASTNode
    attr_accessor :name
    attr_accessor :args
    attr_accessor :body
    attr_accessor :owner

    def initialize(name, args = [], body = [], owner = nil)
      @name = name
      @args = Array.from args
      @body = Expressions.from body
      @owner = owner
    end

    def ==(other)
      other.class == self.class && other.name == name && other.args == args &&
        other.body == body && other.owner == owner
    end

    def accept_children(visitor)
      args.each {|arg| arg.accept visitor}
      body.accept visitor
      owner.accept visitor if owner
    end

    def to_s
      str = '(def '
      str << "#{owner}:" if owner
      str << name.to_s
      str << "(#{args.join ' '})" if args.any?
      str << " #{body}" if body.any?
      str << ')'
    end

    def simple_clone
      self.class.new name, args, body, owner
    end
  end

  class StaticDef < Def
  end
end