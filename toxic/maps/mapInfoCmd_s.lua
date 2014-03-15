CmdMgr.register{
	name = 'respawn',
	aliases = {'rs'},
	desc = "Checks if map supports respawn",
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		local map
		if(mapName) then
			map = findMap(mapName)
		else
			local room = ctx.player.room
			map = getCurrentMap(room)
		end
		
		if(map) then
			local rs = map:getSetting('respawn') or get('race.respawnmode')
			local rstime = map:getSetting('respawntime') or get('race.respawntime')
			if(rs == 'none') then
				scriptMsg("Respawn is disabled.")
			else
				scriptMsg("Respawn is enabled (%u seconds).", rstime or 10)
			end
		else
			privMsg(ctx.player, "Cannot find map!")
		end
	end
}

CmdMgr.register{
	name = 'mapinfo',
	desc = "Displays information about map",
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		local map
		if(mapName) then
			map = findMap(mapName)
		else
			local room = ctx.player.room
			map = getCurrentMap(room)
		end
		
		if(map) then
			local data = DbQuerySingle('SELECT played, rates, rates_count, removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
			local rating = data.rates_count > 0 and(('%.1f'):format(data.rates / data.rates_count)) or 0
			
			scriptMsg("Map name: %s - Played: %u - Rating: %.1f (rated by %u players)%s",
				map:getName(), data.played, rating, data.rates_count, data.removed and ' - Removed: '..data.removed or '')
		else
			privMsg(ctx.player, "Cannot find map!")
		end
	end
}

CmdMgr.register{
	name = 'author',
	aliases = {'creator'},
	desc = "Checks map author name",
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		local map
		if(mapName) then
			map = findMap(mapName)
		else
			local room = ctx.player.room
			map = getCurrentMap(room)
		end
		
		if(map) then
			local author = map:getInfo('author')
			
			if(author) then
				scriptMsg("Map %s has been made by %s.", map:getName(), author)
			else
				scriptMsg("Map %s has no author.", map:getName())
			end
		else
			privMsg(ctx.player, "Cannot find map!")
		end
	end
}

CmdMgr.register{
	name = 'maps',
	desc = "Displays total maps count",
	func = function(ctx)
		local maps = getMapsList()
		scriptMsg("Total maps count: %u.", maps:getCount())
	end
}

CmdMgr.register{
	name = 'mapstats',
	desc = "Shows statistics for each map type",
	func = function(ctx)
		local rows = DbQuery('SELECT map, removed, rates, rates_count, played FROM '..MapsTable)
		local maps_data = {}
		for i, data in ipairs(rows) do
			maps_data[data.map] = data
		end
		
		local maps = getMapsList()
		local map_type_stats = {}
		for i, map in maps:ipairs() do
			local map_name = map:getName()
			local map_type = map:getType()
			assert(map_type)
			
			local stats = map_type_stats[map_type]
			if(not stats) then
				stats = { count = 0, removed = 0, rates = 0, rates_count = 0, played = 0 }
				map_type_stats[map_type] = stats
			end
			
			stats.count = stats.count + 1
			local map_id = map:getId()
			if(maps_data[map_id]) then
				if(maps_data[map_id].removed) then
					stats.removed = stats.removed + 1
				end
				stats.rates = stats.rates + maps_data[map_id].rates
				stats.rates_count = stats.rates_count + maps_data[map_id].rates_count
				stats.played = stats.played + maps_data[map_id].played
			end
		end
		scriptMsg("Total maps count: %u", maps:getCount())
		for map_type, stats in pairs(map_type_stats) do
			local rating = 0
			if(stats.rates_count > 0) then
				rating = stats.rates / stats.rates_count
			end
			
			scriptMsg("%s - count: %u - played: %u - removed: %u - rating: %s",
				map_type.name, stats.count, stats.played, stats.removed, formatNumber(rating, 1))
		end
	end
}

CmdMgr.register{
	name = 'played',
	desc = "Shows how many times map has been played",
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		local map
		if(mapName) then
			map = findMap(mapName)
		else
			local room = ctx.player.room
			map = getCurrentMap(room)
		end
		
		if(map) then
			local rows = DbQuery('SELECT played FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
			scriptMsg("Map %s has been played %u times.", map:getName(), rows[1].played)
		else
			privMsg(ctx.player, "Cannot find map!")
		end
	end
}

CmdMgr.register{
	name = 'findmap',
	aliases = {'checkmap', 'check'},
	desc = "Searches for a map with specified name",
	args = {
		{'mapName', type = 'str'},
	},
	func = function(ctx, str)
		if(str:len() < 3) then
			privMsg(ctx.player, "Specify at least 3 characters.")
			return
		end
		
		local maps = getMapsList()
		local buf = ''
		local pattern = str:lower()
		for i, map in maps:ipairs() do
			local mapName = map:getName()
			
			if(mapName:lower():find(pattern, 1, true)) then
				buf = buf..((buf ~= '' and ', ') or '')..mapName
				local data = DbQuery('SELECT removed FROM '..MapsTable..' WHERE map=? LIMIT 1', map:getId())
				
				if(data[1].removed) then
					buf = buf..' (removed)'
				end
				
				if(buf:len() > 256) then
					buf = buf..', ..' --third point will be added letter
					break
				end
			end
		end
		
		if(buf == '') then
			scriptMsg("Maps not found for \"%s\".", str)
		else
			scriptMsg("Found maps: %s.", buf)
		end
	end
}

CmdMgr.register{
	name = 'mapqueue',
	aliases = {'nextmapqueue', 'queue'},
	desc = "Displays map queue",
	func = function(ctx)
		local queue = ''
		local room = ctx.player.room
		if(room.mapQueue and #room.mapQueue > 0) then
			for i, map in ipairs(room.mapQueue) do
				local mapName = map:getName()
				queue = queue..', '..i..'. '..mapName
			end
			queue = queue:sub(3)
		else
			queue = MuiGetMsg("empty", ctx.player.el)
		end
		privMsg(ctx.player, "Next map queue: %s.", queue)
	end
}

CmdMgr.register{
	name = 'mapid',
	desc = "Displays current map ID",
	func = function(ctx)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		scriptMsg("Map ID: %u", map:getId())
	end
}
