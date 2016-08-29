require("luatest.stdlib.base")
do
  local self, __base = Object:newclass(Object, "Object")
  Object = self
  function __base:to_s()
    return self:class():to_s()
  end
end
do
  local self, __base = Object:newclass(Class, "Class")
  Class = self
  function __base:to_s()
    return self["@name"]
  end
end
do
  local self, __base = Object:newclass(Greeter, "Greeter")
  Greeter = self
  function __base:initialize(name, age)
    self["@name"] = name
    self["@age"] = age
    return self["@age"]
  end
  function self:foo()
    return print("foo")
  end
  function __base:say_hello()
    print("hello", self["@name"])
    return self["@name"]
  end
end
local g = Greeter:new("Joy", 12)
g:say_hello()
do
  local self, __base = Object:newclass(Point, "Point")
  Point = self
  function __base:initialize(x, y)
    self["@x"] = x
    self["@y"] = y
    return self["@y"]
  end
  function __base:magnitude()
    return nil
  end
  function __base:x()
    return self["@x"]
  end
  function __base:y()
    return self["@y"]
  end
end
local p = Point:new(3, 4)
print("p.x = ", p:x())
print("p.y = ", p:y())
print(p:magnitude())
print("the class of p is "..p:class():to_s())
print(Greeter:foo())