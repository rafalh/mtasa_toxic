Map = {}
Map.__mt = {__index = Map}
Map.idCache = {}

-- Used by map.lua and map_fixing.lua
function setMetaSetting(node, setting, value)
	local subnode = xmlFindChild(node, "settings", 0)
	if(not subnode) then
		subnode = xmlCreateChild(node, "settings")
		if(not subnode) then
			return false
		end
	end
	
	local found, success = false, false
	local i = 0
	local success = false
	
	while(true) do
		local subnode2 = xmlFindChild(subnode, "setting", i)
		if(not subnode2) then break end
		i = i + 1
		
		local name = xmlNodeGetAttribute(subnode2, "name")
		if(name == setting or name == "#"..setting or name == "@"..setting or name == "*"..setting) then
			if(value) then
				success = xmlNodeSetAttribute(subnode2, "value", toJSON(value))
			else
				success = xmlDestroyNode(subnode2)
				i = i - 1
			end
			found = true
		end
	end
	
	if(not found) then
		subnode2 = xmlCreateChild(subnode, "setting")
		if(subnode2) then
			success =
				xmlNodeSetAttribute(subnode2, "name", "#"..setting) and
				xmlNodeSetAttribute(subnode2, "value", toJSON(value))
		else
			success = false
		end
	end
	
	return success
end

function Map:getName()
	return self:getInfo("name") or self.resName
end

function Map:getInfo(name)
	return getResourceInfo(self.res, name)
end

function Map:setInfo(attr, value)
	if ( not setResourceInfo ( self.res, attr, value ) ) then return false end
	
	local node = xmlLoadFile ( ":"..getResourceName ( self.res ).."/meta.xml" )
	if ( not node ) then return false end
	
	local subnode = xmlFindChild ( node, "info", 0 )
	if ( not subnode ) then xmlUnloadFile ( node ) return false end
	
	xmlNodeSetAttribute ( subnode, attr, value )
	
	local result = xmlSaveFile ( node )
	xmlUnloadFile ( node )
	return result
end

function Map:getSetting(name)
	return get(self.resName.."."..name)
end

function Map:setSetting(setting, value)
	-- Note: this doesn't work for ZIP resources and I have no idea how to fix it...
	local node = xmlLoadFile ( ":"..getResourceName ( self.res ).."/meta.xml" )
	if ( not node ) then
		return false
	end
	
	local success = setMetaSetting ( node, setting, value )
	
	if ( success ) then
		success = xmlSaveFile ( node )
	end
	xmlUnloadFile ( node )
	
	return success
end

function Map:start()
	local mapManagerRes = getResourceFromName("mapmanager")
	if(not mapManagerRes or getResourceState(mapManagerRes) ~= "running") then
		return false
	end
	
	return call(mapManagerRes, "changeGamemodeMap", self.res)
end

function Map:getId()
	assert ( self.res )
	
	local map_id = Map.idCache[self.res]
	if ( map_id ) then
		return map_id
	end
	
	local map = getResourceName ( self.res )
	local rows = DbQuery ( "SELECT map FROM rafalh_maps WHERE name=? LIMIT 1", map )
	if ( not rows or not rows[1] ) then
		DbQuery ( "INSERT INTO rafalh_maps (name) VALUES(?)", map )
		rows = DbQuery ( "SELECT map FROM rafalh_maps WHERE name=? LIMIT 1", map )
	end
	
	map_id = rows[1].map
	Map.idCache[self.res] = map_id
	return map_id
end

function Map:getType()
	local mapName = self:getName()
	
	local mapNameLower = mapName:lower ()
	for i, mapType in ipairs (g_MapTypes) do
		if (not mapType.pattern or mapNameLower:match(mapType.pattern)) then
			return mapType
		end
	end
	
	return false
end

function Map:isForbidden()
	local max_map_rep = SmGetUInt ("max_map_rep", 0)
	if (self == getLastMap() and max_map_rep > 0 and g_MapRepeats >= max_map_rep) then
		return "Map cannot be repeated!"
	end
	
	local mapType = self:getType()
	local forced = mapType.others_in_row >= mapType.max_others_in_row
	
	-- if it's not forced, let's check if there are other forced types
	if (not forced) then
		for i, mapType in ipairs (g_MapTypes) do
			if (mapType.others_in_row >= mapType.max_others_in_row) then
				return "You can vote only for race map now! Allowed types: %s.", mapType.name
			end
		end
	end
	
	local mapId = self:getId()
	local rows = DbQuery ("SELECT removed FROM rafalh_maps WHERE map=? LIMIT 1", mapId)
	
	if (rows[1].removed ~= "") then
		return "This map has been removed!"
	end
	
	return false
end

function Map:getElements(type)
	assert(type)
	return getElementsByType(type, self.resRoot)
end

function Map:getPath()
	return ":"..getResourceName(self.res)
end

function Map:getRespawn()
	local respawnStr = self:getSetting("respawn") or get("race.respawnmode")
	return respawnStr ~= "none"
end

function Map.create(res)
	local self = setmetatable({}, Map.__mt)
	
	assert(res)
	self.res = res
	self.resRoot = getResourceRootElement(res)
	self.resName = getResourceName(res)
	
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
	i = i + 1
	local map = self:get(i)
	if(not map) then return end
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
