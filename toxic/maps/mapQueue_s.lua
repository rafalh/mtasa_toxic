addEvent("onAddMapToQueueReq", true)

function MqAdd(room, map, display_msg, player)
	assert(type(room) == "table")
	
	if(not room.mapQueue) then
		room.mapQueue = {}
	end
	
	table.insert(room.mapQueue, map)
	local pos = #room.mapQueue
	
	local mapName = map:getName()
	local mapType = map:getType()
	
	for i, mapType2 in ipairs(g_MapTypes) do
		if (mapType2 ~= mapType) then
			mapType2.others_in_row = mapType2.others_in_row + 1
		else
			mapType2.others_in_row = 0
		end
	end
	
	if(pos == 1) then
		triggerClientEvent(g_Root, "onClientSetNextMap", g_Root, mapName)
	end
	
	if(display_msg) then
		if (player) then
			if(type(player) ~= "table") then
				player = Player.fromEl(player)
			end
			outputMsg(room.el, Styles.maps, "%s has been added to next map queue (pos. %u.) by %s!", mapName, pos, player:getName(true))
		else
			outputMsg(room.el, Styles.maps, "%s has been added to next map queue (pos. %u.)!", mapName, pos)
		end
	end
	
	return pos
end

function MqRemove(room, pos)
	if(not room.mapQueue) then return false end
	
	pos = pos or #room.mapQueue
	local map = table.remove(room.mapQueue, pos)
	if(not map) then return end
	
	local mapType = map:getType()
	
	for i, map_type2 in ipairs (g_MapTypes) do
		if (map_type2 ~= mapType) then
			map_type2.others_in_row = math.max(map_type2.others_in_row - 1, 0)
		end
	end
	
	if(pos == 1) then
		local nextMap = room.mapQueue[1]
		local nextMapName = nextMap and nextMap:getName()
		triggerClientEvent(g_Root, "onClientSetNextMap", g_Root, nextMapName)
	end
	
	return map
end

function MqPop(room)
	assert(room)
	if(not room.mapQueue) then return false end
	
	local map = table.remove (room.mapQueue, 1)
	
	local nextMap = room.mapQueue[1]
	local nextMapName = nextMap and nextMap:getName()
	triggerClientEvent(g_Root, "onClientSetNextMap", g_Root, nextMapName)
	
	return map
end

function MqGetMapPos(room, map)
	if(not room.mapQueue) then return false end
	
	for i, map2 in ipairs(room.mapQueue) do
		if (map2 == map) then
			return i
		end
	end
	return false
end

local function MqOnAddReq(mapResName)
	if (not hasObjectPermissionTo(client, "resource."..g_ResName..".nextmap", false)) then return end
	
	local room = Player.fromEl(client).room
	local map = false
	
	local mapRes = getResourceFromName(mapResName)
	if(mapRes) then
		map = Map.create(mapRes)
	else
		local mapMgrRes = getResourceFromName("mapmgr")
		if(mapMgrRes and getResourceState(mapMgrRes) == "running" and call(mapMgrRes, "isMap", mapResName)) then
			map = Map.create(mapResName)
		end
	end
	
	if(map) then
		MqAdd(room, map, true, client)
	else
		outputDebugString("getResourceFromName failed "..tostring(mapResName), 2)
	end
end

addInitFunc(function()
	addEventHandler("onAddMapToQueueReq", g_ResRoot, MqOnAddReq)
end)
