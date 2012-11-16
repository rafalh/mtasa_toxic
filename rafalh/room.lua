Room = {}
Room.__mt = {__index = Room}
Room.elMap = {}

function Room:destroy()
	Room.elMap[self.el] = nil
end

function Room.create(el)
	if(Room.elMap[el]) then
		return Room.elMap[el]
	end
	
	local self = setmetatable({}, Room.__mt)
	self.el = el
	Room.elMap[self.el] = self
	return self
end

addEventHandler("onElementDestroy", g_Root, function()
	local room = Room.elMap[source]
	if(not room) then return end
	room:destroy()
end)
