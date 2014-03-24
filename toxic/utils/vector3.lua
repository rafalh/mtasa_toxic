Vector3 = Class('Vector3')

function Vector3.__mt.__index:len()
	return (self[1]^2 + self[2]^2 + self[3]^2)^0.5
end

function Vector3.__mt.__index:len2()
	return self[1]^2 + self[2]^2 + self[3]^2
end

function Vector3.__mt.__index:normalize()
	return self / self:len()
end

function Vector3.__mt.__index:dist(vec)
	return ((self[1] - vec[1])^2 + (self[2] - vec[2])^2 + (self[3] - vec[3])^2)^0.5
end

function Vector3.__mt.__index:distFromSeg(a, b)
	-- Based on http://www.softsurfer.com/Archive/algorithm_0102/algorithm_0102.htm
	local v = b - a
    local w = self - a
	
    local c1 = w:dot(v)
    if(c1 <= 0) then
        return self:dist(a)
	end
	
    local c2 = v:dot(v)
    if(c2 <= c1) then
        return self:dist(b)
	end
	
    local b = c1 / c2
    local Pb = a + v * b
    return self:dist(Pb)
end

function Vector3.__mt.__index:dot(vec)
	return self[1]*vec[1] + self[2]*vec[2] + self[3]*vec[3]
end

function Vector3.__mt:__add(vec)
	return Vector3(self[1] + vec[1], self[2] + vec[2], self[3] + vec[3])
end

function Vector3.__mt:__sub(vec)
	return Vector3(self[1] - vec[1], self[2] - vec[2], self[3] - vec[3])
end

function Vector3.__mt:__unm()
	return Vector3(-self[1], -self[2], -self[3])
end

function Vector3.__mt.__mul(a, b)
	if(type(b) ~= 'table') then
		return Vector3(a[1]*b, a[2]*b, a[3]*b)
	elseif(type(a) ~= 'table') then
		return Vector3(b[1]*a, b[2]*a, b[3]*a)
	else
		--assert(a.cls == Vector3 and b.cls == Vector3, tostring(a.cls)..' '..tostring(b.cls))
		return Vector3(a[1]*b[1], a[2]*b[2], a[3]*b[3])
	end
end

function Vector3.__mt:__div(a)
	return Vector3(self[1]/a, self[2]/a, self[3]/a)
end

function Vector3.__mt:__eq(vec)
	return self[1] == vec[1] and self[2] == vec[2] and self[3] == vec[3]
end

function Vector3.__mt:__tostring()
	return ('(%.2f %.2f %.2f)'):format(self[1], self[2], self[3])
end

function Vector3.__mt.__index:init(x, y, z)
	self[1] = x or 0
	self[2] = y or 0
	self[3] = z or 0
end

if(Test) then
	function Test.checkCloseVector3(vec, validVec, eps, descr)
		local diff = math.max(
			math.abs(vec[1] - validVec[1]),
			math.abs(vec[2] - validVec[2]),
			math.abs(vec[3] - validVec[3]))
		Test.check(diff < eps, 'expected '..tostring(validVec)..', got '..tostring(vec)..' (diff '..diff..')'..(descr and ' '..descr or ''), 1)
	end
end

-- Simple test
#if(TEST) then
	Test.register('Vector3', function()
		Test.checkEq(((Vector3(1, 0, 0) + Vector3(0, 1, 0)) * 2), Vector3(2, 2, 0))
		Test.checkEq(Vector3(0, 0, 5):normalize(), Vector3(0, 0, 1))
	end)
#end
