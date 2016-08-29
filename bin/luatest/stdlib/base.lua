do
  local __base = {}
  local self = {__base}

  function __base:clone()
    local object = {}
    for k, v in pairs(self) do
      object[k] = v
    end

    setmetatable(object, {__index = self})

    return object
  end

  function self:newclass(class, name)
    if not class then
      class = Class:new(name)
      self:newbase(class)
    end

    return class, rawget(class, "__base")
  end

  function self:newbase(class)
    if not rawget(class, "__base") then
      local base =  {}
      setmetatable(base, {__index = rawget(self, "__base")})
      base["@class"] = class
      rawset(class, "__base", base)
    end
  end
  BasicObject = self
end

Object = {}
setmetatable(Object, {__index = BasicObject})
BasicObject:newbase(Object)
Class = {}
setmetatable(Class, {__index = Object})
Object:newbase(Class)

do
  local self, __base =  BasicObject:newclass(Object, "Object")
  Object = self

  function self:new( ... )
    local object = {}
    setmetatable(object, {__index = rawget(self, "__base")})
    object:initialize(...)

    return object
  end

  function __base:initialize(...)
    -- body
  end

  function __base:class()
    return self["@class"]
  end
end

do
  local self, __base = Object:newclass(Class, "Class")
  Class = self

  function __base:new( ... )
    local object = {}
    setmetatable(object, {__index = rawget(self, "__base")})
    object:initialize(...)

    return object
  end

  function __base:initialize(name)
    self["@name"] = name
    self["@class"] = Class
  end
end
