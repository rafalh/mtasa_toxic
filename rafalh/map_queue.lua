g_NextMapQueue = {}

addEvent ("onAddMapToQueueReq", true)

function MqAdd(map, display_msg, player)
	table.insert(g_NextMapQueue, map)
	local pos = #g_NextMapQueue
	
	local mapName = map:getName()
	local mapType = map:getType()
	
	for i, mapType2 in ipairs(g_MapTypes) do
		if (mapType2 ~= mapType) then
			mapType2.others_in_row = mapType2.others_in_row + 1
		else
			mapType2.others_in_row = 0
		end
	end
	
	if (pos == 1) then
		triggerClientEvent (g_Root, "onClientSetNextMap", g_Root, mapName)
	end
	
	if (display_msg) then
		if (player) then
			customMsg (128, 255, 196, "%s has been added to next map queue (pos. %u.) by %s!", mapName, pos, getPlayerName (player))
		else
			customMsg (128, 255, 196, "%s has been added to next map queue (pos. %u.)!", mapName, pos)
		end
	end
	
	return pos
end

function MqRemove(pos)
	local map = table.remove(g_NextMapQueue, pos)
	if(not map) then return end
	
	local mapType = map:getType()
	
	for i, map_type2 in ipairs (g_MapTypes) do
		if (map_type2 ~= mapType) then
			map_type2.others_in_row = math.max(map_type2.others_in_row - 1, 0)
		end
	end
	
	if(pos == 1) then
		local nextMap = g_NextMapQueue[1]
		local nextMapName = nextMap and nextMap:getName()
		triggerClientEvent (g_Root, "onClientSetNextMap", g_Root, nextMapName)
	end
	
	return map
end

function MqClear ()
	while(#g_NextMapQueue > 0) do
		MqRemove(#g_NextMapQueue)
	end
end

function MqPop ()
	local map = table.remove (g_NextMapQueue, 1)
	
	local nextMap = g_NextMapQueue[1]
	local nextMapName = nextMap and nextMap:getName()
	triggerClientEvent (g_Root, "onClientSetNextMap", g_Root, nextMapName)
	
	return map
end

function MqGetMapPos(map)
	for i, map2 in ipairs(g_NextMapQueue) do
		if (map2 == map) then
			return i
		end
	end
	return false
end

local function MqOnAddReq (map_res_name)
	if (not hasObjectPermissionTo (client, "resource.rafalh.nextmap", false)) then return end
	
	local map_res = getResourceFromName (map_res_name)
	local map = map_res and Map.create(map_res)
	if (map) then
		MqAdd(map, true, client)
	else
		outputDebugString ("getResourceFromName failed", 2)
	end
end

addEventHandler("onAddMapToQueueReq", g_ResRoot, MqOnAddReq)
