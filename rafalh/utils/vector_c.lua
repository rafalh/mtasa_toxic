Vector = {}
Vector.__mt = {__index = {}}

function Vector.__mt.__index:len()
	return (self[1]^2 + self[2]^2 + self[3]^2)^0.5
end

function Vector.__mt.__index:len2()
	return self[1]^2 + self[2]^2 + self[3]^2
end

function Vector.__mt.__index:dist(vec)
	return ((self[1] - vec[1])^2 + (self[2] - vec[2])^2 + (self[3] - vec[3])^2)^0.5
end

function Vector.__mt.__index:distFromSeg(a, b)
	-- Based on http://www.softsurfer.com/Archive/algorithm_0102/algorithm_0102.htm
	local v = b - a
    local w = self - a
	
    local c1 = w:dot(v)
    if ( c1 <= 0 ) then
        return self:dist(a)
	end
	
    local c2 = v:dot(v)
    if ( c2 <= c1 ) then
        return self:dist(b)
	end
	
    local b = c1 / c2
    local Pb = a + v * b
    return self:dist(Pb)
end

function Vector.__mt.__index:dot(vec)
	return self[1]*vec[1] + self[2]*vec[2] + self[3]*vec[3]
end

function Vector.create(x, y, z)
	return setmetatable({x or 0, y or 0, z or 0}, Vector.__mt)
end

function Vector.__mt:__add(vec)
	return Vector.create(self[1] + vec[1], self[2] + vec[2], self[3] + vec[3])
end

function Vector.__mt:__sub(vec)
	return Vector.create(self[1] - vec[1], self[2] - vec[2], self[3] - vec[3])
end

function Vector.__mt.__mul(a, b)
	if(type(a) == "table") then
		return Vector.create(a[1]*b, a[2]*b, a[3]*b)
	else
		return Vector.create(b[1]*a, b[2]*a, b[3]*a)
	end
end

function Vector.__mt:__div(a)
	return Vector.create(self[1]/a, self[2]/a, self[3]/a)
end

function Vector.__mt:__eq(vec)
	return self[1] == vec[1] and self[2] == vec[2] and self[3] == vec[3]
end

function Vector.__mt:__tostring()
	return "("..tostring(self[1]).." "..tostring(self[2]).." "..tostring(self[3])..")"
end

-- Allow creating vectors by calling Vector(x, y, z)
local mt = {}
function mt:__call(x, y, z)
	return Vector.create(x, y, z)
end
setmetatable(Vector, mt)

-- Simple test
--assert(((Vector(1, 0, 0) + Vector(0, 1, 0)) * 2) == Vector(2, 2, 0))
