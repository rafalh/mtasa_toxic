Vector2 = {}
Vector2.__mt = {__index = {}}

function Vector2.__mt.__index:len()
	return (self[1]^2 + self[2]^2)^0.5
end

function Vector2.__mt.__index:len2()
	return self[1]^2 + self[2]^2
end

function Vector2.__mt.__index:dist(vec)
	return ((self[1] - vec[1])^2 + (self[2] - vec[2])^2)^0.5
end

function Vector2.create(x, y)
	return setmetatable({x or 0, y or 0}, Vector2.__mt)
end

function Vector2.__mt:__add(vec)
	return Vector2(self[1] + vec[1], self[2] + vec[2])
end

function Vector2.__mt:__sub(vec)
	return Vector2(self[1] - vec[1], self[2] - vec[2])
end

function Vector2.__mt.__mul(a, b)
	if(type(a) == "table") then
		return Vector2(a[1]*b, a[2]*b)
	else
		return Vector2(b[1]*a, b[2]*a)
	end
end

function Vector2.__mt:__div(a)
	return Vector2.create(self[1]/a, self[2]/a)
end

function Vector2.__mt:__eq(vec)
	return self[1] == vec[1] and self[2] == vec[2]
end

function Vector2.__mt:__tostring()
	return "("..tostring(self[1]).." "..tostring(self[2])..")"
end

-- Allow creating vectors by calling Vector2(x, y, z)
local mt = {}
function mt:__call(x, y)
	return Vector2.create(x, y)
end
setmetatable(Vector2, mt)

-- Simple test
--assert(((Vector2(1, 0) + Vector2(0, 1)) * 2) == Vector2(2, 2))
