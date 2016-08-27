require 'ruby_parser'
require_relative 'ast'
require 'pp'

module Ruby2Lua
  class Transform
    class << self
      def rule(type, &block)
        @__transform_rules ||= {}
        @__transform_rules[type] = block
      end

      def rules
        @__transform_rules || {}
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@__transform_rules, rules.dup)
      end
    end

    def initialize(&block)
      @rules = []

      if block
        instance_eval(&block)
      end
    end

    def rule(type, &block)
      @rules[type] = block
    end

    def rules
      rules = self.class.rules
      @rules.each do |type, block|
        rules[type] = block
      end
      rules
    end

    def apply(sexp)
      type = sexp.sexp_type
      sexp.each_with_index do |child, idx|
        next unless Sexp === child
        sexp[idx] = apply(child)
      end
      if rules.has_key? type
        return rules[type].call(sexp.rest)
      else
        return sexp
      end
    end
  end

  class ASTTransform < Transform
    rule(:lit)      do |s|
      NumberLit.new s.first
    end
    rule(:nil)      do |s|
      NilLit.new
    end
    rule(:str)      do |s|
      StringLit.new s.first
    end
    rule(:lvar)     do |s|
      Variable.new s.first
    end
    rule(:self)     do |s|
      Variable.new :self
    end
    rule(:ivar)     do |s|
      InstanceVar.new s.first
    end
    rule(:args)     do |s|
      s.map {|arg| Argument.new(arg)}
    end
    rule(:const)    do |s|
      Const.new s.first
    end
    rule(:colon2)   do |s|
      const = Const.new(s[1] || 'Main')
      const.owner = s.first
      const
    end
    rule(:call)     do |s|
      Call.new(s[1], s[2..-1], s[0])
    end
    rule(:iasgn)    do |s|
      target = InstanceVar.new s.first
      Assign.new(target, s[1])
    end
    rule(:lasgn)    do |s|
      target = Variable.new s.first
      Assign.new(target, s[1])
    end
    rule(:block)    do |s|
      Block.new s
    end
    rule(:module)   do |s|
      name = s.first.is_a?(Const) ? s.first : Const.new(s.first)
      ModuleDef.new name, s[1..-1]
    end
    rule(:class)    do |s|
      name = s.first.is_a?(Const) ? s.first : Const.new(s.first)
      ClassDef.new name, s[2..-1], s[1]
    end
    rule(:defn)     do |s|
      Def.new s.first, s[1], s[2..-1]
    end
    rule(:defs)     do |s|
      case s.first
      when Const, Variable
        StaticDef.new s[1], s[2], s[3..-1], s.first
      else
        raise "Error when parse function"
      end
    end
  end
end