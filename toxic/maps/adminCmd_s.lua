local g_LastRedo = 0

local REMOVED_MAPS_ORG_PATH = '[removed_maps]'
local RESTORED_MAPS_ORG_PATH = '[restored_maps]'

addEvent('onClientDisplayNextMapGuiReq', true)

CmdMgr.register{
	name = 'removemap',
	aliases = {'remmap'},
	desc = "Removes map from server",
	cat = 'Admin',
	accessRight = AccessRight('remmap'),
	args = {
		{'reason', type = 'str'},
	},
	func = function(ctx, reason)
		local map = getCurrentMap(ctx.player.room)
		if(not map) then return end
		
		reason = reason..' (removed by '..ctx.player:getAccountName()..')'
		local now = getRealTime().timestamp

		DbQuery('UPDATE '..MapsTable..' SET removed=?, removed_timestamp=? WHERE map=?', reason, now, map:getId())

		outputMsg(g_Root, Styles.red, "%s has been removed by %s!", map:getName(), ctx.player:getName(true))

		startRandomMap(ctx.player.room)

		-- rename resource after map change
		setTimer(function ()
			renameResource(map.res, map.resName, REMOVED_MAPS_ORG_PATH)
		end, 1000, 1)
	end
}

CmdMgr.register{
	name = 'restoremap',
	desc = "Restores previously removed map",
	cat = 'Admin',
	accessRight = AccessRight('restoremap'),
	args = {
		{'mapName', type = 'str'},
	},
	func = function(ctx, mapName)
		local map = findMap(mapName, true)
		
		if(not map) then
			privMsg(ctx.player, "Cannot find map \"%s\" or it has not been removed!", mapName)
			return
		end
		
		-- Note: after renameResource call resource handle is no longer valid so map name is retrived here
		local mapName = map:getName()
		DbQuery('UPDATE '..MapsTable..' SET removed=NULL, removed_timestamp=NULL WHERE map=?', map:getId())
		renameResource(map.res, map.resName, RESTORED_MAPS_ORG_PATH)

		outputMsg(g_Root, Styles.green, "%s has been restored by %s!", mapName, ctx.player:getName(true))
	end
}

CmdMgr.register{
	name = 'map',
	desc = "Changes current map",
	cat = 'Admin',
	accessRight = AccessRight('command.setmap', true),
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		if(mapName) then
			local map
			if(mapName:lower() == 'random') then
				map = getRandomMap()
			else
				map = findMap(mapName, false)
			end
			
			if(not map) then
				privMsg(ctx.player, "Cannot find map \"%s\"!", mapName)
				return
			end
			
			local rows = DbQuery('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
			if(rows[1].removed) then
				privMsg(ctx.player, "%s has been removed!", map:getName())
				return
			end
			
			GbCancelBets()
			local room = ctx.player.room
			map:start(room)
		else
			addEvent('onClientDisplayChangeMapGuiReq', true)
			triggerClientEvent(ctx.player.el, 'onClientDisplayChangeMapGuiReq', g_ResRoot)
		end
	end
}

local function AddMapToQueue(room, map)
	local map_id = map:getId()
	local rows = DbQuery ('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id)
	if (rows[1].removed) then
		local map_name = map:getName()
		privMsg(source, "%s has been removed!", map_name)
	elseif(not MqAdd(room, map, true, source)) then
		outputMsg(source, Styles.red, "Map queue is full!")
	end
end

CmdMgr.register{
	name = 'nextmap',
	desc = "Adds next map to queue",
	cat = 'Admin',
	accessRight = AccessRight('nextmap'),
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		if(not mapName) then
			triggerClientEvent(ctx.player.el, 'onClientDisplayNextMapGuiReq', g_ResRoot)
			return
		end
		
		local room = ctx.player.room
		local mapNameLower = mapName:lower()
		local map
		if(mapNameLower == 'random') then
			map = getRandomMap()
		elseif(mapNameLower == 'redo') then
			map = getCurrentMap(room)
		else
			map = findMap(mapName, false)
		end
		
		if(map) then
			source = ctx.player.el -- FIXME
			AddMapToQueue(room, map)
		else
			privMsg(ctx.player, "Cannot find map \"%s\"!", mapName)
		end
	end
}

-- For Admin Panel
local function onSetNextMap (mapName)
	if(hasObjectPermissionTo(client, 'resource.'..g_ResName..'.nextmap', false)) then
		local map = findMap(mapName, false)
		if(map) then
			local pdata = Player.fromEl(client)
			AddMapToQueue(pdata.room, map)
		end
	end
end

CmdMgr.register{
	name = 'cancelnext',
	desc = "Removes last map from queue",
	cat = 'Admin',
	accessRight = AccessRight('nextmap'),
	func = function(ctx)
		local room = ctx.player.room
		local map = MqRemove(room)
		if(map) then
			outputMsg(room.el, Styles.maps, "%s has been removed from map queue by %s!", map:getName(), ctx.player:getName(true))
		else
			privMsg(ctx.player, "Map queue is empty!")
		end
	end
}

CmdMgr.register{
	name = 'redo',
	desc = "Restarts current map",
	cat = 'Admin',
	accessRight = AccessRight('command.setmap', true),
	func = function(ctx)
		local now = getRealTime().timestamp
		local dt = now - g_LastRedo
		local room = ctx.player.room
		local map = getCurrentMap(room)
		local redoLimit = 10
		if(dt < redoLimit) then
			privMsg(ctx.player, "You cannot redo yet! Please wait %u seconds.", redoLimit - dt)
		elseif(map) then
			GbCancelBets()
			g_LastRedo = now
			map:start(room)
		end
	end
}

CmdMgr.register{
	name = 'moveremovedmaps',
	cat = 'Admin',
	accessRight = AccessRight('remmap'),
	func = function(ctx)
		local num = 0
		local rows = DbQuery('SELECT map, name FROM '..MapsTable..' WHERE removed IS NOT NULL')
		for i, row in ipairs(rows) do
			local res = getResourceFromName(row['name'])
			if res and getResourceOrganizationalPath(res) ~= REMOVED_MAPS_ORG_PATH then
				renameResource(res, row['name'], REMOVED_MAPS_ORG_PATH)
				num = num + 1
			end
		end
		privMsg(ctx.player, "Moved %u removed maps!", num)
	end
}

addInitFunc(function()
	addEvent('setNextMap_s', true)
	addEventHandler('setNextMap_s', g_Root, onSetNextMap)
end)
