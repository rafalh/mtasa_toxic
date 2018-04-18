g_OldVehicleWeapons = nil
local g_RaceRes = Resource('race')

CmdMgr.register{
	name = 'setmapname',
	aliases = {'smn'},
	accessRight = AccessRight('setmapname'),
	args = {
		{'newName', type = 'str'},
	},
	func = function(ctx, newName)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(map and map:setInfo('name', newName)) then
			MiUpdateInfo()
			scriptMsg("New map name: %s", newName)
		else
			privMsg(ctx.player, "Error! Cannot set map name.")
		end
	end
}

CmdMgr.register{
	name = 'setmaptype',
	aliases = {'smt', 'setmaptag'},
	accessRight = AccessRight('setmapname'),
	args = {
		{'newType', type = 'str'},
	},
	func = function(ctx, newMapType)
		local mapTypes = { dd = 'DD', dm = 'DM', race = 'Race', cnr = 'CnR', tdd = 'TDD', tdm = 'TDM', fun = 'Fun' }
		local newMapType = mapTypes[newMapType:lower()] or newMapType
		
		local room = ctx.player.room
		local map = getCurrentMap(room)
		local name = map and map:getName()
		local newName = map and '['..newMapType..'] '..(name:match('^%[%w+%]%s*(.*)$') or name)
		
		if(map and map:setInfo('name', newName)) then
			MiUpdateInfo()
			scriptMsg("New map name: %s", newName)
		else
			privMsg(ctx.player, "Error! Cannot set map name.")
		end
	end
}

CmdMgr.register{
	name = 'setmapauthor',
	aliases = {'setmapcreator', 'sc'},
	desc = "Sets current map author",
	accessRight = AccessRight('setmapcreator'),
	args = {
		{'newAuthor', type = 'str'},
	},
	func = function(ctx, newAuthor)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(map and map:setInfo('author', newAuthor)) then
			MiUpdateInfo()
			scriptMsg("New map creator: %s", newAuthor)
		else
			privMsg(ctx.player, "Error! Cannot set map creator.")
		end
	end
}

CmdMgr.register{
	name = 'setrespawn',
	aliases = {'setrs'},
	desc = "Sets current map respawn time",
	accessRight = AccessRight('setrs'),
	args = {
		{'seconds|no|auto', type = 'str'},
	},
	func = function(ctx, val)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(map) then
			local sec = touint(val, 0)
			local respawn, respawntime = nil, nil
			
			if(sec > 0) then
				respawn = 'timelimit'
				respawntime = sec
			elseif(val == '0' or val == 'false' or val == 'no')  then
				respawn = 'none'
			elseif(val == 'true' or val == 'yes')  then
				respawn = 'timelimit'
			elseif(val == 'auto') then
				respawn = nil
			else
				privMsg(ctx.player, "Invalid respawn value: %s", val)
				return
			end
			
			if(respawntime) then
				map:setSetting('respawntime', respawntime)
			end
			if(map:setSetting('respawn', respawn)) then
				scriptMsg("Respawn will be set to %s (%s) in the next round!", respawn or 'auto', respawntime or 'auto')
			else
				privMsg(ctx.player, "Failed to set respawn.")
			end
		end
	end
}

CmdMgr.register{
	name = 'setmapghostmode',
	aliases = {'setmapgm', 'smgm'},
	desc = "Enables or disabled ghostmode for current map",
	accessRight = AccessRight('setmapgm'),
	args = {
		{'true/false/auto', type = 'str'},
	},
	func = function(ctx, val)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(map) then
			if(val == 'false' or val == 'no') then
				val = 'false'
			elseif(val == 'true' or val == 'yes') then
				val = 'true'
			elseif(val == 'auto') then
				val = nil
			else
				privMsg(ctx.player, "Invalid ghostmode value: %s", val)
				return
			end
			
			if(map:setSetting('ghostmode', val)) then
				scriptMsg("Ghost Mode will be set to %s in the next round!", val or 'auto')
			else
				privMsg(ctx.player, "Failed to set map Ghost Mode.")
			end
		end
	end
}

CmdMgr.register{
	name = 'setmaptimelimit',
	aliases = {'smtimelimit', 'settimelimit'},
	desc = "Sets current map time limit",
	accessRight = AccessRight('setmaptimelimit'),
	args = {
		{'timeLimit', type = 'str'},
	},
	func = function(ctx, val)
		local t = split(val, ':')
		local h, m, s = tonumber(t[#t-2] or 0), tonumber(t[#t-1] or 0), tonumber(t[#t])
		if(h and m and s) then
			local map = getCurrentMap()
			
			if(map) then
				local limit = h * 3600 + m * 60 + s
				if(limit > 0) then
					map:setSetting('duration', limit)
					scriptMsg("Time limit will be set to %s in the next round!", val)
				else
					map:setSetting('duration', nil)
					scriptMsg("Time limit will not be set in the next round!")
				end
			end
		else
			privMsg(ctx.player, "Time limit format: %s", '[h:m:]s')
		end
	end
}

CmdMgr.register{
	name = 'setmapvehwep',
	aliases = {'smvehwep'},
	desc = "Enables or disables vehicle weapons in current map",
	accessRight = AccessRight('setmapvehwep'),
	args = {
		{'true/false/auto', type = 'str'},
	},
	func = function(ctx, val)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(map) then
			if(val == 'true' or val == 'yes') then
				map:setSetting('vehicleweapons', 'true')
				scriptMsg("Vehicle weapons will be enabled in the next round!")
			elseif(val == 'false' or val == 'no') then
				map:setSetting('vehicleweapons', 'false')
				scriptMsg("Vehicle weapons will be disabled in the next round!")
			elseif(val == 'auto') then
				map:setSetting('vehicleweapons', nil)
				scriptMsg("Vehicle weapons will not be set in the next round!")
			else
				privMsg(ctx.player, "Invalid argument: %s", val)
			end
		end
	end
}

CmdMgr.register{
	name = 'setmaphuntermg',
	aliases = {'smhuntermg', 'smhuntmg'},
	desc = "Enables or disables Hunter minigun in current map",
	accessRight = AccessRight('setmaphuntermg'),
	args = {
		{'true/false/auto', type = 'str'},
	},
	func = function(ctx, val)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(map) then
			if(val == 'true' or val == 'yes') then
				map:setSetting('hunterminigun', 'true')
				scriptMsg("Hunter mini-gun will be enabled in the next round!")
			elseif(val == 'false' or val == 'no') then
				map:setSetting('hunterminigun', 'false')
				scriptMsg("Hunter mini-gun will be disabled in the next round!")
			elseif(val == 'auto') then
				map:setSetting('hunterminigun', nil)
				scriptMsg("Hunter mini-gun will be set to auto in the next round!")
			else
				privMsg(ctx.player, "Invalid argument: %s", val)
			end
		end
	end
}

CmdMgr.register{
	name = 'setmapwaveheight',
	aliases = {'smwaveh'},
	desc = "Sets current map wave height",
	accessRight = AccessRight('setmapwaveheight'),
	args = {
		{'num/auto', type = 'str'},
	},
	func = function(ctx, val)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		local h = tonumber(val)
		
		if(not map) then
			privMsg(ctx.player, "No map is running now!")
		elseif(h) then
			map:setSetting('waveheight', h)
			scriptMsg("Wave height will be set to %.1f in the next round!", h)
		elseif(val == 'auto') then
			map:setSetting('waveheight', nil)
			scriptMsg("Wave height will set to auto in the next round!")
		else
			privMsg(ctx.player, "Invalid argument: %s", val)
		end
	end
}

CmdMgr.register{
	name = 'setcompmode',
	aliases = {'setmapcompmode', 'setmaplegacymode'},
	desc = "Enables or disables compatiblity mode for current map (makes Race resource compatible with old MTA:RM)",
	accessRight = AccessRight('setcompmode'),
	args = {
		{'enabled', type = 'bool'},
	},
	func = function(ctx, enabled)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		
		if(not map) then
			privMsg(ctx.player, "No map is running now!")
		elseif(enabled) then
			map:setSetting('compmode', 'true')
			scriptMsg("Compatibility mode will be enabled in the next round!")
		else
			map:setSetting('compmode', nil)
			scriptMsg("Compatibility mode will be disabled in the next round!")
		end
	end
}

CmdMgr.register{
	name = 'setmapmaxspeed',
	desc = "Sets max speed in map meta so AntiCheat can use it to determine if player drives too fast",
	accessRight = AccessRight('setmapmaxspeed'),
	args = {
		{'maxSpeed', type = 'str'},
	},
	func = function(ctx, maxSpeed)
		local room = ctx.player.room
		local map = getCurrentMap(room)
		local maxSpeedInt = touint(maxSpeed)
		if(not map) then
			privMsg(ctx.player, "No map is running now!")
		elseif(not maxSpeedInt and maxSpeed ~= 'false') then
			privMsg(ctx.player, "Invalid argument: %s", maxSpeed)
		elseif(not map:setSetting('maxspeed', maxSpeedInt)) then
			privMsg(ctx.player, "Failed to set maximal speed!")
		else
			scriptMsg("Maximal speed will be set to %u in the next round!", maxSpeed)
		end
	end
}

CmdMgr.register{
	name = 'vehicleweapons',
	aliases = {'vehwep'},
	desc = "Toggles vehicle weapons for currently running map",
	accessRight = AccessRight('vehicleweapons'),
	func = function(ctx)
		if(not g_RaceRes:isReady()) then return end
		
		local old_enabled, enabled = get('*race.vehicleweapons')
		if(not g_OldVehicleWeapons) then
			g_OldVehicleWeapons = old_enabled
		end
		if(old_enabled == 'false') then
			enabled = 'true'
			outputMsg(g_Root, Styles.green, "Vehicle weapons enabled by %s!", ctx.player:getName(true))
		else
			enabled = 'false'
			outputMsg(g_Root, Styles.red, "Vehicle weapons disabled by %s!", ctx.player:getName(true))
		end
		set('*race.vehicleweapons', enabled)
		triggerEvent('onSettingChange', getResourceRootElement(g_RaceRes.res), 'vehicleweapons', g_OldVehicleWeapons, enabled)
	end
}

local function GenMapResName(map)
	local name = map:getName()
	if(name:sub(1, 5) ~= 'race-') then
		name = 'race-'..name
	end
	name = name:gsub('[^a-zA-Z0-9%[%]-]+', '')
	name = name:gsub('-+', '-')
	return name
end

local function FixMapResName(map)
	local map_res_name = getResourceName(map.res)
	local new_map_res_name = GenMapResName(map)
	
	if(map_res_name == new_map_res_name) then
		return 0, 'Name is already ok'
	end
	
	local res = getResourceFromName(new_map_res_name)
	if(res and res ~= map.res) then
		return -1, 'Name is already used by other resource('..map_res_name..' -> '..new_map_res_name..')'
	end
	
	if(map_res_name:lower() == new_map_res_name:lower()) then
		if(not renameResource(map_res_name, '_'..map_res_name) and
			not renameResource('_'..map_res_name, new_map_res_name)) then
			return -1, 'renameResource failed'
		end
	else
		if(not renameResource(map_res_name, new_map_res_name)) then
			return -1, 'renameResource failed'
		end
	end
	
	DbQuery('UPDATE '..MapsTable..' SET name=? WHERE name=?', new_map_res_name, map_res_name)
	
	return 1, 'Renamed '..map_res_name..' to '..new_map_res_name
end

local g_FixMapResNameTimer = false

local function FixAllMapsResName(player)
	local start = getTickCount()
	local dt, count, fails = 0, 0, 0
	local maps = getMapsList()
	local start2 = start
	
	for i, map in maps:ipairs() do
		local dt = getTickCount() - start2
		if(dt > 100) then
			privMsg(player, i..'/'..maps:getCount())
			coroutine.yield()
			start2 = getTickCount()
		end
		
		local ret, status = FixMapResName(map)
		if(ret < 0) then
			fails = fails + 1
			privMsg(player, "Failed: %s", status)
		end
		count = count + 1
	end
	
	local dt = getTickCount() - start
	privMsg(player, "Finished in %u ms: %u failures, %u/%u maps processed.", dt, fails, count, maps:getCount())
end

CmdMgr.register{
	name = 'fixmapresname',
	accessRight = AccessRight('fixmapresname'),
	args = {
		{'mapName', type = 'str', defVal = false},
	},
	func = function(ctx, mapName)
		if(mapName == 'all') then
			if(g_FixMapResNameTimer) then return end
			
			local co = coroutine.create(FixAllMapsResName)
			coroutine.resume(co, ctx.player.el)
			if(coroutine.status(co) ~= 'dead') then
				g_FixMapResNameTimer = setTimer(function()
					coroutine.resume(co)
					if(coroutine.status(co) == 'dead') then
						killTimer(g_FixMapResNameTimer)
						g_FixMapResNameTimer = false
					end
				end, 100, 0)
			end
		else
			local room = ctx.player.room
			local map = mapName and findMap(mapName) or getCurrentMap(room)
			if(not map) then
				privMsg(ctx.player, 'Cannot find map!')
			end
			
			local ok, status = FixMapResName(map)
			if(ok) then
				privMsg(ctx.player, '%s', status)
			else
				privMsg(ctx.player, "Failed: %s", status)
			end
		end
	end
}

local function DetectMapType(map)
	local map_res_name = getResourceName(map.res)
	local node = xmlLoadFile(':'..map_res_name..'/meta.xml')
	if(not node) then return false end
	
	local subnode = xmlFindChild(node, 'map', 0)
	if(not subnode) then
		xmlUnloadFile(node)
		return false
	end
	
	local src = xmlNodeGetAttribute(subnode, 'src')
	xmlUnloadFile(node)
	if(not src) then return false end
	
	local node = xmlLoadFile(':'..map_res_name..'/'..src)
	if(not node) then return false end
	
	local map_type = 'DD'
	local children = xmlNodeGetChildren(node)
	for i, subnode in ipairs(children) do
		local tag = xmlNodeGetName(subnode)
		
		if(tag == 'checkpoint') then
			map_type = 'Race'
			break
		elseif(tag == 'racepickup') then
			local attr = xmlNodeGetAttributes(subnode)
			if(attr.type == 'vehiclechange' and attr.vehicle == '425') then
				map_type = 'DM'
				break
			end
		end
	end
	
	xmlUnloadFile(node)
	return map_type
end

CmdMgr.register{
	name = 'fixmaptags',
	accessRight = AccessRight('fixmaptags'),
	args = {
		{'fix', type = 'bool', defVal = false},
	},
	func = function(ctx, fix)
		local count = 0
		
		local maps = getMapsList()
		for i = 1, maps:getCount() do
			local map = maps:get(i)
			local mapName = map:getName()
			
			if(not mapName:match('^%[%w+%] .*$')) then
				count = count + 1
				
				local newMapName
				local map_type, mapNameWithoutTag = mapName:match('^%[(%w+)%]%s*(.*)$') -- no space
				if(map_type) then -- Add space
					newMapName = '['..map_type..'] '..mapNameWithoutTag
				else
					map_type = DetectMapType(map)
					newMapName = map_type and '['..map_type..'] '..mapName
				end
				
				if(not fix) then
					privMsg(ctx.player, 'To do: %s -> %s', mapName, tostring(newMapName))
				elseif(newMapName and map:setInfo('name', newMapName)) then
					privMsg(ctx.player, 'Fixed: %s', newMapName)
				else
					privMsg(ctx.player, 'Failed to fix: %s', mapName)
				end
			end
		end
		
		privMsg(ctx.player, '%d/%d maps %s.', count, maps:getCount(), fix and 'fixed' or 'detected')
	end
}

local function MocCleanup()
	if(g_OldVehicleWeapons) then
		set('*race.vehicleweapons', g_OldVehicleWeapons)
	end
end

addInitFunc(function()
	addEventHandler('onResourceStop', g_ResRoot, MocCleanup)
end)
