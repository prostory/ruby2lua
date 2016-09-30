require_relative 'extend'

module Ruby2Lua
  class Visitor
  end

  class ASTNode
    include Enumerable
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

  class ASTLeaf < ASTNode
    attr_accessor :token

    def initialize(sexp)
      @token = sexp.first
    end

    def [](i)
      raise "has no any child for #{token}"
    end

    alias child []
    alias value token

    def each
      yield
    end

    def size
      0
    end

    def ==(other)
      other.class = self.class && other.token == token
    end

    def to_s
      token.to_s
    end

    def simple_clone
      self.class.new value
    end
  end

  class ASTList < ASTNode
    attr_accessor :children

    def self.from(obj)
      case obj
      when nil
        new []
      when ::Array
        new obj
      when self
        new obj.children
      else
        new [obj]
      end
    end

    def initialize(sexp)
      @children = ::Array.from sexp
    end

    def [](i)
      children[i]
    end

    alias child []

    def size
      children.size
    end

    def each
      children.each { |child| yield child }
    end

    def accept_children(visitor)
      children.each { |child| child.accept(visitor) if child.is_a?(ASTNode) }
    end

    def location
      children.find {|child| child.location != nil}
    end

    def ==(other)
      other.class == self.class && other.children == children
    end

    def to_s
      "(#{children.join(' ')})"
    end

    def simple_clone
      self.class.new children.map { |child| child.clone if child.is_a?(ASTNode) }
    end
  end

  class Block < ASTList
    def empty?
      children.empty?
    end

    def last
      children.last
    end
  end

  class Nil < ASTLeaf
  end

  class Lit < ASTLeaf
  end

  class True < ASTLeaf
  end

  class False < ASTLeaf
  end

  class Str < ASTLeaf
  end

  class Xstr < ASTLeaf
  end

  class Evstr < ASTList
    def initialize(list)
      super([Call.from(:to_s, [], list[0])])
    end

    def value
      child(0)
    end
  end

  class Dstr < ASTList
    def string
      child(0)
    end

    def values
      children[1..-1]
    end
  end

  class Lvar < ASTLeaf
    alias name value
  end

  class Ivar < Lvar
    def initialize(sexp)
      @token = sexp[0].to_s.gsub(/^@/, '').to_sym
    end
  end

  class Cvar < Lvar
    def initialize(sexp)
      @token = sexp[0].to_s.gsub(/^@@/, '').to_sym
    end
  end

  class Gvar < Lvar
    def initialize(sexp)
      @token = sexp[0].to_s.gsub(/^\$/, '').to_sym
    end
  end

  class Self < Lvar
  end

  class Const < ASTLeaf
    alias name value

    def owner
      nil
    end
  end

  class Colon2 < ASTList
    def name
      child(1)
    end

    def owner
      child(0)
    end
  end

  class Colon3 < Const
  end

  class Args < ASTList
    alias values children
  end

  class Splat < ASTList
    def value
      child(0)
    end
  end

  class Block_pass < ASTList
    def value
      child(0)
    end
  end

  class Call < ASTList
    def self.from(name, args = [], obj = nil)
      self.new [obj, name, *args]
    end

    def name
      child(1)
    end

    def obj
      child(0)
    end

    def args
      child(2..-1)
    end
  end

  class Yield < ASTList
    alias args children
  end

  class Return < ASTList
    alias values children
  end

  class Lasgn < ASTList
    def initialize(list)
      @children = [Lvar.new([list[0]]), list[1]]
    end

    def target
      child(0)
    end

    def value
      child(1)
    end
  end

  class Iasgn < Lasgn
    def initialize(list)
      @children = [Ivar.new([list[0]]), list[1]]
    end
  end

  class Cvasgn < Lasgn
    def initialize(list)
      @children = [Cvar.new([list[0]]), list[1]]
    end
  end

  class Gasgn < Lasgn
    def initialize(list)
      @children = [Gvar.new([list[0]]), list[1]]
    end
  end

  class Cdecl < Lasgn
    def initialize(list)
      @children = [list[0].is_a?(ASTNode)? list[0] : Const.new([list[0]]), list[1]]
    end
  end

  class Module < ASTList
    def initialize(list)
      @children = [Const.new([list[0]]), Block.from(list[1..-1])]
    end

    def name
      child(0)
    end

    def body
      child(1)
    end
  end

  class Class < Module
    def initialize(list)
      @children = [Const.new([list[0]]), list[1]? Const.new([list[1]]) : nil, Block.from(list[2..-1])]
    end

    def superclass
      child(1)
    end

    def body
      child(2)
    end
  end

  class Defn < ASTList
    def initialize(list)
      @children = [*list[0..1], Block.from(list[2..-1])]
    end

    def name
      child(0)
    end

    def args
      child(1)
    end

    def body
      child(2)
    end
  end

  class Defs < Defn
    def initialize(list)
      @children = [*list[0..2], Block.from(list[3..-1])]
    end

    def owner
      child(0)
    end

    def name
      child(1)
    end

    def args
      child(2)
    end

    def body
      child(3)
    end
  end

  class If < ASTList
    def initialize(list)
      super([list[0], Block.from(list[1]), Block.from(list[2])])
    end

    def cond
      child(0)
    end

    def then
      child(1)
    end

    def else
      child(2)
    end
  end

  class While < ASTList
    def initialize(list)
      super([list[0], Block.from(list[1])])
    end

    def cond
      child(0)
    end

    def body
      child(1)
    end
  end

  class Until < While
  end

  class Case < ASTList
    def obj
      child(0)
    end

    def branches
      child(1..-2)
    end

    def else
      child(-1)
    end
  end

  class When < ASTList
    def initialize(list)
      super([list[0], Block.from(list[1..-1])])
    end

    def array
      child(0)
    end

    def body
      child(1)
    end
  end

  class Rescue < ASTList
    def initialize(list)
      super([Block.from(list[0]), *list[1..-1]])
    end

    def body
      child(0)
    end

    def resbody
      child(1)
    end
  end

  class Resbody < ASTList
    def initialize(list)
      super([list[0], Block.from(list[1..-1])])
    end

    def array
      child(0)
    end

    def body
      child(1)
    end
  end

  class Ensure < ASTList
    def initialize(list)
      super([list[0], Block.from(list[1..-1])])
    end

    def rescue
      child(0)
    end
    def body
      child(1)
    end
  end

  class Array < ASTList
  end

  class Hash < ASTList
  end

  class Iter < ASTList
    def initialize(list)
      super([*list[0..1], Block.from(list[2])])
    end

    def obj
      child(0)
    end

    def args
      child(1)
    end

    def body
      child(2)
    end
  end
end