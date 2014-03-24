Vector2 = Class('Vector2')

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
	assert(type(self) == 'table')
	assert(type(vec) == 'table')
	return Vector2(self[1] + vec[1], self[2] + vec[2])
end

function Vector2.__mt:__sub(vec)
	return Vector2(self[1] - vec[1], self[2] - vec[2])
end

function Vector2.__mt.__mul(a, b)
	if(type(b) ~= 'table') then
		return Vector2(a[1]*b, a[2]*b)
	elseif(type(a) ~= 'table') then
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
	return ('(%.2f %.2f)'):format(self[1], self[2])
end

function Vector2.__mt.__index:init(x, y)
	self[1] = x or 0
	self[2] = y or 0
end

-- Simple test
#if(TEST) then
	Test.register('Vector2', function()
		local vx = Vector2(1, 0)
		local vy = Vector2(0, 1)
		Test.checkEq(((vx + vy) * 2), Vector2(2, 2))
		Test.checkEq(tostring(vx), '(1.00 0.00)')
	end)
#end
