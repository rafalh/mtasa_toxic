Rect = {}
Rect.__mt = {__index = {}}

function Rect.__mt:__eq(rc)
	return self[1] == rc[1] and self[2] == rc[2]
end

function Rect.__mt:__tostring()
	return "("..tostring(self[1]).." "..tostring(self[1] + self[2])..")"
end

function Rect.__mt.__concat(a, b)
	return tostring(a)..tostring(b)
end

-- Allow creating rectangles by calling Rect(a, b)
local mt = {}
function mt:__call(pos, size)
	return setmetatable({pos or Vector2(), size or Vector2()}, Rect.__mt)
end
function mt:__tostring()
	return "Rect"
end
setmetatable(Rect, mt)


RelRect = {}
RelRect.__mt = {__index = {}}

function RelRect.__mt.__index:setAbs(rc)
	self[1] = rc
end

function RelRect.__mt.__index:setRel(rc)
	self[2] = rc
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
	return "(abs "..tostring(self[1])..", rel "..tostring(self[1] + self[2])..")"
end

function RelRect.__mt.__concat(a, b)
	return tostring(a)..tostring(b)
end

-- Allow creating rectangles by calling RelRect(a, b)
local mt = {}
function mt:__call(absRect, relRect)
	return setmetatable({absRect or Rect(), relRect or Rect()}, RelRect.__mt)
end
function mt:__tostring()
	return "RelRect"
end
setmetatable(RelRect, mt)
