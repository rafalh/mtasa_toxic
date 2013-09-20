Map = {}
Map.__mt = {__index = Map}
Map.idCache = {}

local g_RoomMgrRes = Resource('roommgr')
local g_MapMgrRes = Resource('mapmanager')
local g_MapMgrNewRes = Resource('mapmgr')


-- Used by map.lua and map_fixing.lua
function setMetaSetting(node, setting, value)
	local subnode = xmlFindChild(node, 'settings', 0)
	if(not subnode) then
		subnode = xmlCreateChild(node, 'settings')
		if(not subnode) then
			return false
		end
	end
	
	local found, success = false, false
	local i = 0
	
	while(true) do
		local subnode2 = xmlFindChild(subnode, 'setting', i)
		if(not subnode2) then break end
		i = i + 1
		
		local name = xmlNodeGetAttribute(subnode2, 'name')
		if(name == setting or name == '#'..setting or name == '@'..setting or name == '*'..setting) then
			if(value) then
				success = xmlNodeSetAttribute(subnode2, 'value', toJSON(value))
			else
				success = xmlDestroyNode(subnode2)
				i = i - 1
			end
			found = true
		end
	end
	
	if(not found) then
		subnode2 = xmlCreateChild(subnode, 'setting')
		if(subnode2) then
			success =
				xmlNodeSetAttribute(subnode2, 'name', '#'..setting) and
				xmlNodeSetAttribute(subnode2, 'value', toJSON(value))
		else
			success = false
		end
	end
	
	return success
end

function getMetaSetting(node, setting)
	local subnode = xmlFindChild(node, 'settings', 0)
	if(not subnode) then return nil end
	
	local i = 0
	while(true) do
		local subnode2 = xmlFindChild(subnode, 'setting', i)
		if(not subnode2) then break end
		i = i + 1
		
		local name = xmlNodeGetAttribute(subnode2, 'name')
		if(name == setting or name == '#'..setting or name == '@'..setting or name == '*'..setting) then
			local value = xmlNodeGetAttribute(subnode2, 'value')
			return fromJSON(value) or value
		end
	end
	
	return nil
end

function Map:getName()
	return self:getInfo('name') or self.resName
end

function Map:getInfo(name)
	if(self.res) then
		return getResourceInfo(self.res, name)
	end
	
	if(self.path and g_MapMgrNewRes:isReady()) then
		return g_MapMgrNewRes:call('getMapInfo', self.path, name)
	end
	
	return false
end

function Map:setInfo(attr, value)
	if(not self.res) then return end
	
	if(not setResourceInfo(self.res, attr, value)) then return false end
	
	local node = xmlLoadFile(self:getPath()..'/meta.xml')
	if(not node) then return false end
	
	local subnode = xmlFindChild(node, 'info', 0)
	if(not subnode) then xmlUnloadFile(node) return false end
	
	xmlNodeSetAttribute(subnode, attr, value)
	
	local result = xmlSaveFile(node)
	xmlUnloadFile(node)
	return result
end

function Map:getSetting(name)
	if(not self.res) then return end
	return get(self.resName..'.'..name)
end

function Map:setSetting(setting, value)
	-- Note: this doesn't work for ZIP resources and I have no idea how to fix it...
	local node = xmlLoadFile(self:getPath()..'/meta.xml')
	if(not node) then
		return false
	end
	
	local success = setMetaSetting ( node, setting, value )
	
	if(success) then
		success = xmlSaveFile(node)
	end
	xmlUnloadFile(node)
	
	return success
end

function Map:start(room)
	assert(room)
	
	if(g_MapMgrRes:isReady()) then
		return g_MapMgrRes:call('changeGamemodeMap', self.res)
	end
	
	if(g_RoomMgrRes:isReady()) then
		return g_RoomMgrRes:call('startRoomMap', room.el, self.path)
	end
	
	return false
end

function Map:getId()
	local map_id = Map.idCache[self.res or self.path]
	if(map_id) then
		return map_id
	end
	
	local map = (self.res and getResourceName(self.res)) or self.path
	local rows = DbQuery('SELECT map FROM '..MapsTable..' WHERE name=? LIMIT 1', map)
	if(not rows or not rows[1]) then
		local now = getRealTime().timestamp
		DbQuery('INSERT INTO '..MapsTable..' (name, added_timestamp) VALUES(?, ?)', map, now)
		rows = DbQuery('SELECT map FROM '..MapsTable..' WHERE name=? LIMIT 1', map)
	end
	
	map_id = rows[1].map
	Map.idCache[self.res or self.path] = map_id
	return map_id
end

function Map:getType()
	local mapName = self:getName()
	
	local mapNameLower = mapName:lower()
	for i, mapType in ipairs(g_MapTypes) do
		if(not mapType.pattern or mapNameLower:match(mapType.pattern)) then
			return mapType
		end
	end
	
	return false
end

function Map:isForbidden(room)
	assert(room)
	
	local max_map_rep = Settings.max_map_rep
	if(self == getLastMap(room) and max_map_rep > 0 and room.mapRepeats >= max_map_rep) then
		return "Map cannot be repeated!"
	end
	
	local mapType = self:getType()
	local forced = mapType.max_others_in_row and (mapType.others_in_row >= mapType.max_others_in_row)
	
	-- if it's not forced, let's check if there are other forced types
	if(not forced) then
		for i, mapType in ipairs(g_MapTypes) do
			local curForced = mapType.max_others_in_row and (mapType.others_in_row >= mapType.max_others_in_row)
			if(curForced) then
				return "You can vote only for race map now! Allowed types: %s.", mapType.name
			end
		end
	end
	
	local mapId = self:getId()
	local rows = DbQuery ('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', mapId)
	
	if(rows[1].removed ~= '') then
		return "This map has been removed!"
	end
	
	return false
end

function Map:getElements(type)
	assert(type and self.resRoot)
	return getElementsByType(type, self.resRoot)
end

function Map:getPath()
	return ':'..getResourceName(self.res)
end

function Map:getRespawn()
	local respawnStr = self:getSetting('respawn') or get('race.respawnmode')
	return respawnStr ~= 'none'
end

function Map.create(res)
	local self = setmetatable({}, Map.__mt)
	
	assert(res)
	if(type(res) == 'userdata') then
		self.res = res
		self.resRoot = getResourceRootElement(res)
		self.resName = getResourceName(res)
	else
		self.path = res
		assert(type(self.path) == 'string', type(self.path))
	end
	
	return self
end

function Map.__mt:__eq(map)
	return self.res == map.res
end

MapList = {}
MapList.__mt = {__index = MapList}

function MapList:get(i)
	local mapRes = self.resList[i]
	return mapRes and Map.create(mapRes)
end

function MapList:getCount()
	return #self.resList
end

function MapList:iterator(i)
	local map = self:get(i)
	if(not map) then return end
	i = i + 1
	return i, map
end

function MapList:ipairs()
	return MapList.iterator, self, 1
end

function MapList:remove(i)
	local mapRes = table.remove(self.resList, i)
	return mapRes and Map.create(mapRes)
end

function MapList.create(mapResList)
	local self = setmetatable({}, MapList.__mt)
	
	self.resList = mapResList
	
	return self
end
