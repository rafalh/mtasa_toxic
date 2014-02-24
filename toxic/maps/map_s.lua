Map = Class('Map')
Map.idCache = {}

local g_RoomMgrRes = Resource('roommgr')
local g_MapMgrRes = Resource('mapmanager')
local g_MapMgrNewRes = Resource('mapmgr')

function Map.__mt.__index:getName()
	return self:getInfo('name') or self.resName
end

function Map.__mt.__index:getInfo(name)
	if(self.res) then
		return getResourceInfo(self.res, name)
	end
	
	if(self.path and g_MapMgrNewRes:isReady()) then
		return g_MapMgrNewRes:call('getMapInfo', self.path, name)
	end
	
	return false
end

function Map.__mt.__index:setInfo(attr, value)
	if(not self.res) then return end
	
	if(not setResourceInfo(self.res, attr, value)) then return false end
	
	local meta = MetaFile(self:getPath()..'/meta.xml')
	local success = meta:setInfo(attr, value)
	if(success) then
		success = meta:save()
	end
	meta:close()
	return success
end

function Map.__mt.__index:getSetting(name)
	if(not self.res) then return end
	return get(self.resName..'.'..name)
end

function Map.__mt.__index:setSetting(setting, value)
	-- Note: this doesn't work for ZIP resources and I have no idea how to fix it...
	local meta = MetaFile(self:getPath()..'/meta.xml')
	local success = meta:setSetting(setting, value)
	if(success) then
		success = meta:save()
	end
	meta:close()
	return success
end

function Map.__mt.__index:start(room)
	assert(room)
	
	if(g_MapMgrRes:isReady()) then
		return g_MapMgrRes:call('changeGamemodeMap', self.res)
	elseif(g_RoomMgrRes:isReady()) then
		return g_RoomMgrRes:call('startRoomMap', room.el, self.path)
	end
	
	return false
end

function Map.__mt.__index:getId()
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

function Map.__mt.__index:getType()
	local mapName = self:getName()
	
	local mapNameLower = mapName:lower()
	for i, mapType in ipairs(g_MapTypes) do
		if(not mapType.pattern or mapNameLower:match(mapType.pattern)) then
			return mapType
		end
	end
	
	return false
end

function Map.__mt.__index:isForbidden(room)
	assert(room)
	
	-- Check if map can be repeated
	local max_map_rep = Settings.max_map_rep
	if(self == getLastMap(room) and max_map_rep > 0 and room.mapRepeats >= max_map_rep) then
		return "Map cannot be repeated!"
	end
	
	-- Check if other map type is forced
	if(g_PlayersCount > 1) then
		local mapType = self:getType()
		local forced = mapType.max_others_in_row and (mapType.others_in_row >= mapType.max_others_in_row)
		
		-- if it's not forced, let's check if there are other forced types
		if(not forced) then
			for i, mapType in ipairs(g_MapTypes) do
				local curForced = mapType.max_others_in_row and (mapType.others_in_row >= mapType.max_others_in_row)
				if(curForced) then
					return "You can vote only for %s map now!", mapType.name
				end
			end
		end
	end
	
	-- Check if this map has been removed
	local mapId = self:getId()
	local data = DbQuerySingle('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', mapId)
	if(data.removed ~= '') then
		return "This map has been removed!"
	end
	
	return false
end

function Map.__mt.__index:getElements(type)
	assert(type and self.resRoot)
	return getElementsByType(type, self.resRoot)
end

function Map.__mt.__index:getPath()
	return ':'..getResourceName(self.res)
end

function Map.__mt.__index:getRespawn()
	local respawnStr = self:getSetting('respawn') or get('race.respawnmode')
	return respawnStr ~= 'none'
end

function Map.__mt.__index:init(res)
	assert(res)
	if(type(res) == 'userdata') then
		self.res = res
		self.resRoot = getResourceRootElement(res)
		self.resName = getResourceName(res)
	else
		self.path = res
		assert(type(self.path) == 'string', type(self.path))
	end
end

function Map.__mt:__eq(map)
	return self.res == map.res
end
