Class = {}
Class.__mt = {__index = {cls = Class}}

function Class.__mt:__call(...)
	if(self.preInit) then
		-- Allow some classes to limit instances count
		local obj = self.preInit(...)
		if(obj) then return obj end
	end
	
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
	return 'Class'
end
function mt.__concat(a, b)
	return tostring(a)..tostring(b)
end
setmetatable(Class, mt)

#if(TEST) then
addInitFunc(function()
	Test.register('Class', function()
		A = Class('A')
		A.x = 1
		A.y = 32
		function A.__mt.__index:test() return 'A test' end
		function A.__mt.__index:test2() return 'A test2' end
		
		B = Class('B', A)
		B.y = 16
		function B.__mt.__index:test() return 'B test' end
		
		Test.checkEq(A.cls, Class)
		Test.checkEq(B.cls, Class)
		Test.checkEq(A.x, 1)
		Test.checkEq(A.y, 32)
		Test.checkEq(B.x, 1)
		Test.checkEq(B.y, 16)
		
		B.x = 2
		Test.checkEq(A.x, 1)
		Test.checkEq(B.x, 2)
		
		local objA = A()
		local objB = B()
		Test.checkEq(tostring(objA), 'A', tostring(objA))
		Test.checkEq(tostring(objB), 'B', tostring(objB))
		Test.checkEq(objA.cls, A)
		Test.checkEq(objB.cls, B)
		Test.checkEq(objA:test(), 'A test')
		Test.checkEq(objA:test2(), 'A test2')
		Test.checkEq(objB:test(), 'B test')
		Test.checkEq(objB:test2(), 'A test2')
	end)
end)
#end
