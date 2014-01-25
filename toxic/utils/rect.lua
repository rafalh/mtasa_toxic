Rect = Class('Rect')

function Rect.__mt:__eq(rc)
	return self[1] == rc[1] and self[2] == rc[2]
end

function Rect.__mt:__tostring()
	return '('..tostring(self[1])..' '..tostring(self[1] + self[2])..')'
end

function Rect.__mt.__index:getOrigin()
	return self[1]
end

function Rect.__mt.__index:getSize()
	return self[2]
end

function Rect.__mt.__index:init(pos, size)
	self[1] = pos or Vector2()
	self[2] = size or Vector2()
end

RelRect = Class('RelRect')

function RelRect.__mt.__index:setAbs(rc)
	self[1] = rc
end

function RelRect.__mt.__index:getAbs(rc)
	return self[1]
end

function RelRect.__mt.__index:setRel(rc)
	self[2] = rc
end

function RelRect.__mt.__index:getRel(rc)
	return self[2]
end

function RelRect.__mt.__index:resolve(parentSize)
	local pos = self[1][1] + self[2][1]/100*parentSize
	local size = self[1][2] + self[2][2]/100*parentSize
	return Rect(pos, size)
end

function RelRect.__mt:__eq(rc)
	return self[1] == rc[1] and self[2] == rc[2]
end

function RelRect.__mt:__tostring()
	return '(abs '..tostring(self[1])..', rel '..tostring(self[1] + self[2])..')'
end

function RelRect.__mt.__index:init(absRect, relRect)
	self[1] = absRect or Rect()
	self[2] = relRect or Rect()
end
