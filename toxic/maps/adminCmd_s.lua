local g_LastRedo = 0

local function CmdRemMap (message, arg)
	local admin = Player.fromEl(source)
	local map = getCurrentMap(admin.room)
	if(not map) then return end
	
	local reason = message:sub (arg[1]:len () + 2)
	if(reason:len() < 5) then
		privMsg(admin.el, "Usage: %s", arg[1].." <reason>")
		return
	end
	
	local account = getPlayerAccount(admin.el)
	reason = reason.." (removed by "..getAccountName(account)..")"
	
	local map_id = map:getId()
	DbQuery("UPDATE "..MapsTable.." SET removed=? WHERE map=?", reason, map_id)
	
	local map_name = map:getName()
	outputMsg(g_Root, Styles.red, "%s has been removed by %s!", map_name, admin:getName(true))
	startRandomMap(admin.room)
end

CmdRegister("remmap", CmdRemMap, "resource."..g_ResName..".remmap", "Removes map from server")
CmdRegisterAlias("removemap", "remmap")

local function CmdRestoreMap (message, arg)
	if(#arg >= 2) then
		local str = message:sub(arg[1]:len () + 2)
		local map = findMap(str, true)
		local admin = Player.fromEl(source)
		
		if(map) then
			local map_name = map:getName()
			local map_id = map:getId()
			DbQuery("UPDATE "..MapsTable.." SET removed='' WHERE map=?", map_id)
			outputMsg(g_Root, Styles.green, "%s has been restored by %s!", map_name, admin:getName(true))
		else privMsg(source, "Cannot find map \"%s\" or it has not been removed!", str) end
	else privMsg(source, "Usage: %s", arg[1].." <map>") end
end

CmdRegister("restoremap", CmdRestoreMap, "resource."..g_ResName..".restoremap", "Restores proviously removed map")

local function CmdMap (message, arg)
	local mapName = message:sub (arg[1]:len () + 2)
	local room = Player.fromEl(source).room
	
	if (mapName:len () > 1) then
		local map
		
		if (mapName:lower () == "random") then
			map = getRandomMap ()
		else
			map = findMap (mapName, false)
		end
		
		if (map) then
			local map_name = map:getName()
			local map_id = map:getId()
			local rows = DbQuery ("SELECT removed FROM "..MapsTable.." WHERE map=? LIMIT 1", map_id)
			
			if (rows[1].removed ~= "") then
				privMsg (source, "%s has been removed!", map_name)
			else
				GbCancelBets ()
				map:start(room)
			end
		else
			privMsg (source, "Cannot find map \"%s\"!", mapName)
		end
	else
		addEvent("onClientDisplayChangeMapGuiReq", true)
		triggerClientEvent(source, "onClientDisplayChangeMapGuiReq", g_ResRoot)
	end
end

CmdRegister("map", CmdMap, "command.setmap", "Changes current map")

local function AddMapToQueue(room, map)
	local map_id = map:getId()
	local rows = DbQuery ("SELECT removed FROM "..MapsTable.." WHERE map=? LIMIT 1", map_id)
	if (rows[1].removed ~= "") then
		local map_name = map:getName()
		privMsg(source, "%s has been removed!", map_name)
	else
		MqAdd(room, map, true, source)
	end
end

local function CmdNextMap (message, arg)
	local mapName = message:sub (arg[1]:len () + 2)
	if (mapName:len () > 1) then
		local room = Player.fromEl(source).room
		assert(type(room) == "table")
		
		local map
		if (mapName:lower () == "random") then
			map = getRandomMap()
		elseif (mapName:lower () == "redo") then
			map = getCurrentMap(room)
		else
			map = findMap(mapName, false)
		end
		
		if (map) then
			AddMapToQueue(room, map)
		else
			privMsg (source, "Cannot find map \"%s\"!", mapName)
		end
	else
		addEvent("onClientDisplayNextMapGuiReq", true)
		triggerClientEvent(source, "onClientDisplayNextMapGuiReq", g_ResRoot)
	end
end

CmdRegister("nextmap", CmdNextMap, "resource."..g_ResName..".nextmap", "Adds next map to queue")
CmdRegisterAlias ("next", "nextmap", true)

-- For Admin Panel
local function onSetNextMap (mapName)
	if (hasObjectPermissionTo(client, "resource."..g_ResName..".nextmap", false)) then
		local map = findMap(mapName, false)
		if(map) then
			local pdata = Player.fromEl(client)
			AddMapToQueue(pdata.room, map)
		end
	end
end

local function CmdCancelNextMap (message, arg)
	local room = Player.fromEl(source).room
	local map = MqRemove(room)
	if(map) then
		local mapName = map:getName()
		outputMsg(room.el, Styles.maps, "%s has been removed from map queue by %s!", mapName, getPlayerName(source))
	else
		privMsg(source, "Map queue is empty!")
	end
end

CmdRegister("cancelnext", CmdCancelNextMap, "resource."..g_ResName..".nextmap", "Removes last map from queue")

local function CmdRedo (message, arg)
	local now = getRealTime ().timestamp
	local room = Player.fromEl(source).room
	local map = getCurrentMap(room)
	if (map and now - g_LastRedo > 10) then
		GbCancelBets ()
		g_LastRedo = now
		map:start(room)
	else
		privMsg(source, "You cannot redo yet! Please wait "..(now - g_LastRedo).." seconds.")
	end
end

CmdRegister("redo", CmdRedo, "command.setmap", "Restarts current map")

addInitFunc(function()
	addEvent("setNextMap_s", true)
	addEventHandler("setNextMap_s", g_Root, onSetNextMap)
end)
