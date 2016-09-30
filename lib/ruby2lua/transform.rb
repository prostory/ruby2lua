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
      type = sexp.sexp_type.capitalize
      sexp.each_with_index do |child, idx|
        next unless Sexp === child
        sexp[idx] = apply(child)
      end
      if Ruby2Lua.const_defined?(type)
        return Ruby2Lua.const_get(type).new(sexp.rest)
      elsif rules.has_key?(type)
        return rules[type].call(sexp.rest)
      else
        return sexp
      end
    end
  end
end