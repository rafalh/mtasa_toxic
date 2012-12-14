Vector = {}
Vector.__mt = {__index = Vector}

function Vector:len()
	return (self[1]^2 + self[2]^2 + self[3]^2)^0.5
end

function Vector:len2()
	return self[1]^2 + self[2]^2 + self[3]^2
end

function Vector:dist(vec)
	return ((self[1] - vec[1])^2 + (self[2] - vec[2])^2 + (self[3] - vec[3])^2)^0.5
end

function Vector:distFromSeg(a, b)
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

function Vector:dot(vec)
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