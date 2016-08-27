BasicObject = {}

function BasicObject:clone()
  local object = {}
  for k, v in pairs(self) do
    object[k] = v
  end

  setmetatable(object, {__index = self})

  return object
end

function BasicObject:new( ... )
  local object = {}
  setmetatable(object, {__index = self})
  object:initialize(...)

  return object
end

function BasicObject:initialize(...)
  -- body
end

Object = BasicObject:new("Object")

Class = Object:new("Class")

function Class:initialize(name)
  self["@name"] = name
  self["@class"] = self["@class"] or Class
end

function Object:initialize(name)
  self["@class"] = self["@class"] or Class:new(name)
end

