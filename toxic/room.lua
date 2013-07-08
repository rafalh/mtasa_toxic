Room = {}
Room.__mt = {__index = {}}
Room.elMap = {}

function Room.__mt.__index:destroy()
	Room.elMap[self.el] = nil
end

function Room.create(el)
	if(Room.elMap[el]) then
		return Room.elMap[el]
	end
	
	local self = setmetatable({}, Room.__mt)
	self.el = el
	Room.elMap[self.el] = self
	
	addEventHandler("onElementDestroy", self.el, Room.onDestroy, false)
	
	return self
end

function Room.onDestroy()
	local self = Room.elMap[source]
	self:destroy()
end
