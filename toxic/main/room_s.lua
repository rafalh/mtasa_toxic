Room = Class('Room')
Room.elMap = {}

function Room.__mt.__index:destroy()
	Room.elMap[self.el] = nil
end

function Room.preInit(el)
	return Room.elMap[el]
end

function Room.__mt.__index:init(el)
	self.el = el
	Room.elMap[self.el] = self
	
	addEventHandler('onElementDestroy', self.el, Room.onDestroy, false)
end

function Room.onDestroy()
	local self = Room.elMap[source]
	self:destroy()
end

function Room.pairs()
	return pairs(Room.elMap)
end
