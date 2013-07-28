Class = {}
Class.__mt = {__index = {cls = Class}}

function Class.__mt:__call(...)
	local obj = setmetatable({}, self.__mt)
	if(obj.init) then
		obj:init(...)
	end
	return obj
end

function Class.__mt:__tostring()
	return self.name
end

function Class.__mt.__concat(a, b)
	return tostring(a)..tostring(b)
end

local mt = {}
function mt:__call(name, parent)
	assert(not parent or parent.cls == Class)
	
	local mt
	if(parent) then
		mt = table.copy(Class.__mt)
		mt.__index = table.merge(parent, mt.__index)
	else
		mt = Class.__mt
	end
	
	local cls = setmetatable({}, mt)
	cls.name = name
	
	if(parent) then
		cls.__mt = table.copy(parent.__mt)
		cls.__mt.__index = table.copy(parent.__mt.__index)
	else
		cls.__mt = {__index = {}}
	end
	
	cls.__mt.__index.cls = cls
	
	function cls.__mt:__tostring()
		return tostring(self.cls)
	end
	
	function cls.__mt.__concat(a, b)
		return tostring(a)..tostring(b)
	end
	
	return cls
end

function mt:__tostring()
	return "Class"
end
function mt.__concat(a, b)
	return tostring(a)..tostring(b)
end
setmetatable(Class, mt)

#TEST = true
#if(TEST) then
	A = Class("A")
	A.x = 1
	A.y = 32
	function A.__mt.__index:test() return "A test" end
	function A.__mt.__index:test2() return "A test2" end
	
	B = Class("B", A)
	B.y = 16
	function B.__mt.__index:test() return "B test" end
	
	assert(A.cls == Class)
	assert(B.cls == Class)
	assert(A.x == 1)
	assert(A.y == 32)
	assert(B.x == 1)
	assert(B.y == 16)
	
	B.x = 2
	assert(A.x == 1)
	assert(B.x == 2)
	
	local objA = A()
	local objB = B()
	assert(tostring(objA) == "A", tostring(objA))
	assert(tostring(objB) == "B", tostring(objB))
	assert(objA.cls == A)
	assert(objB.cls == B)
	assert(objA:test() == "A test")
	assert(objA:test2() == "A test2")
	assert(objB:test() == "B test")
	assert(objB:test2() == "A test2")
#end
