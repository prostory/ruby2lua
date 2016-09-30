--
-- Created by IntelliJ IDEA.
-- User: xiaopeng
-- Date: 16-9-27
-- Time: 下午5:58
-- To change this template use File | Settings | File Templates.
--

local context = {}
local table = table

context.modules = {}

local search = function(k, plist)
    for _, t in ipairs(plist) do
        local v = rawget(t, k)
        if v then return v end
    end
end

function context.extends(class, parent)
    local ancestors = {class}
    if parent then
        for _, mod in ipairs(parent:ancestors()) do
            table.insert(ancestors, mod)
        end
    end
    class["@ancestors"] = ancestors
    return class
end

function context.object(o)
    local obj = o or {}
    setmetatable(obj, {__index = function(t, k)
        return search(k, t:ancestors()) or t:method_missing(k)
    end})

    obj.method_missing = function(self, name)
        error("undefined method '" .. name .. "' for " .. self:inspect())
    end
    
    obj.initialize = function(...)
    end

    return obj
end

function context.class(name, parent, obj)
    local class = context.modules[name] or context.object()
    class["@superclass"] = parent or {}
    class["@modules"] = {}
    context.extends(class, parent)
    class.include = function(self, mod)
        table.insert(self["@modules"], 1, mod)
        table.insert(self["@ancestors"], 2, mod)
    end
    obj = obj or {}
    obj["@class"] = class
    
    class.new = function(self, ...)
      local object = context.object()
      object:initialize(object, ...)

      return object
    end
    
    class.name = function(self)
        return name
    end
    class.to_s = function(self)
        return self:name()
    end
    class.inspect = function(self)
        return self:name()..':Class'
    end
    
    class.ancestors = function(self)
        return self["@ancestors"]
    end

    return class
end

function context.module(name)
    local mod = context.class(name)
    mod.inspect = function(self)
        return self:name()..':Module'
    end

    return mod
end

local BasicObject = context.class("BasicObject")
function BasicObject:a()
    print("BasicObject:a")
end

BasicObject:a()

local Kernel = context.module("Kernel")
function Kernel:a()
    print(self:to_s()..":a")
end

Kernel:a()

local Object = context.class("Object", BasicObject)
Object:include(Kernel)
Object:a()

local Point = {}
function Point:initialize(x, y)
  self["@x"] = x
  self["@y"] = y
end

function Point:to_s()
  return "("..self["@x"]..", "..self["@y"]..")"
end

local Point = context.class("Point", Object, Point)

for _, mod in ipairs(Point:ancestors()) do
  print(mod:to_s())
end

a = Point:new(10, 20)
print(a:to_s())

