Vector2 = {}
Vector2.__mt = {__index = {cls = Vector2}}

function Vector2.__mt.__index:len()
	return (self[1]^2 + self[2]^2)^0.5
end

function Vector2.__mt.__index:len2()
	return self[1]^2 + self[2]^2
end

function Vector2.__mt.__index:dist(vec)
	return ((self[1] - vec[1])^2 + (self[2] - vec[2])^2)^0.5
end

function Vector2.__mt:__add(vec)
	assert(type(self) == "table")
	assert(type(vec) == "table")
	return Vector2(self[1] + vec[1], self[2] + vec[2])
end

function Vector2.__mt:__sub(vec)
	return Vector2(self[1] - vec[1], self[2] - vec[2])
end

function Vector2.__mt.__mul(a, b)
	if(type(b) ~= "table") then
		return Vector2(a[1]*b, a[2]*b)
	elseif(type(a) ~= "table") then
		return Vector2(b[1]*a, b[2]*a)
	else -- both tables
		return Vector2(a[1]*b[1], a[2]*b[2])
	end
end

function Vector2.__mt:__div(a)
	return Vector2(self[1]/a, self[2]/a)
end

function Vector2.__mt:__eq(vec)
	return self[1] == vec[1] and self[2] == vec[2]
end

function Vector2.__mt:__tostring()
	return "("..tostring(self[1]).." "..tostring(self[2])..")"
end

function Vector2.__mt.__concat(a, b)
	return tostring(a)..tostring(b)
end

-- Allow creating vectors by calling Vector2(x, y, z)
local mt = {}
function mt:__call(x, y)
	return setmetatable({x or 0, y or 0}, Vector2.__mt)
end
function mt:__tostring()
	return "Vector2"
end
setmetatable(Vector2, mt)

-- Simple test
--assert(((Vector2(1, 0) + Vector2(0, 1)) * 2) == Vector2(2, 2))
