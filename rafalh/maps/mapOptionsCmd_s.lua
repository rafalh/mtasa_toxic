g_OldVehicleWeapons = nil

local function CmdSetMapName(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			local newName = message:sub(arg[1]:len() + 2)
			
			if(map:setInfo("name", newName)) then
				scriptMsg("New map name: %s", newName)
			else
				privMsg(source, "Error! Cannot set map name.")
			end
		end
	else privMsg(source, arg[1].." <name>") end
end

CmdRegister("setmapname", CmdSetMapName, "resource.rafalh.setmapname")
CmdRegisterAlias("smn", "setmapname")

local function CmdSetMapType(message, arg)
	local map_types = { dd = "DD", dm = "DM", race = "Race", cnr = "CnR", tdd = "TDD", tdm = "TDM", fun = "Fun" }
	local new_map_type = arg[2] and map_types[arg[2]:lower()]
	
	if(new_map_type) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			local name = map:getName()
			local newName = "["..new_map_type.."] "..(name:match("^%[%w+%]%s*(.*)$") or name)
			
			if(map:setInfo("name", newName)) then
				scriptMsg("New map name: %s", newName)
			else
				privMsg(source, "Error! Cannot set map name.")
			end
		end
	else privMsg(source, arg[1].." <dd/dm/race/cnr/tdd/tdm/fun>") end
end

CmdRegister("setmaptype", CmdSetMapType, "resource.rafalh.setmapname")
CmdRegisterAlias("smt", "setmaptype")

local function CmdSetMapCreator(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			local newAuthor = message:sub(arg[1]:len() + 2)
			
			if(map:setInfo("author", newAuthor)) then
				scriptMsg("New map creator: %s", newAuthor)
			else
				privMsg(source, "Error! Cannot set map creator.")
			end
		end
	else privMsg(source, arg[1].." <creator>") end
end

CmdRegister("setmapcreator", CmdSetMapCreator, "resource.rafalh.setmapcreator")
CmdRegisterAlias("sc", "setmapcreator")

local function CmdSetMapRespawn(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			local t = touint(arg[2], 0)
			local respawn, respawntime = nil, nil
			
			if(t and t > 0) then
				respawn = "timelimit"
				respawntime = t
			elseif(t == 0 or arg[2] == "false" or arg[2] == "no")  then
				respawn = "none"
			elseif(arg[2] == "true" or arg[2] == "yes")  then
				respawn = "timelimit"
			else
				respawn = nil
			end
			
			if(respawntime) then
				map:setSetting("respawntime", respawntime)
			end
			if(map:setSetting("respawn", respawn)) then
				scriptMsg("Respawn will be set to %s(%s) in the next round!", respawn or "auto", respawntime or "auto")
			else
				privMsg(source, "Failed to set respawn.")
			end
		end
	else privMsg(source, arg[1].." <seconds/no/auto>") end
end

CmdRegister("setrs", CmdSetMapRespawn, "resource.rafalh.setrs")

local function CmdSetMapGhostmode(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			local val
			if(arg[2] == "false" or arg[2] == "no") then
				val = "false"
			elseif(arg[2] == "true" or arg[2] == "yes") then
				val = "true"
			else
				val = nil
			end
			
			if(map:setSetting("ghostmode", val)) then
				scriptMsg("Ghostmode will be set to %s in the next round!", val or "auto")
			else
				privMsg(source, "Failed to set map ghostmode")
			end
		end
	else privMsg(source, arg[1].." <true/false/auto>") end
end

CmdRegister("setmapgm", CmdSetMapGhostmode, "resource.rafalh.setmapgm")
CmdRegisterAlias("smgm", "setmapgm")

local function CmdSetMapTimeLimit(message, arg)
	local t = split(arg[2] or "", ":")
	local h, m, s = tonumber(t[#t-2] or 0), tonumber(t[#t-1] or 0), tonumber(t[#t])
	if(h and m and s) then
		local map = getCurrentMap()
		
		if(map) then
			local limit = h * 3600 + m * 60 + s
			if(limit > 0) then
				map:setSetting("duration", limit)
				scriptMsg("Timelimit will be set to %s in the next round!", arg[2])
			else
				map:setSetting("duration", nil)
				scriptMsg("Timelimit will not be set in the next round!")
			end
		end
	else privMsg(source, arg[1].." <[h:m:]s>") end
end

CmdRegister("setmaptimelimit", CmdSetMapTimeLimit, "resource.rafalh.setmaptimelimit")
CmdRegisterAlias("smtimelimit", "setmaptimelimit")
CmdRegisterAlias("settimelimit", "setmaptimelimit")

local function CmdSetMapVehicleWeapons(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			if(arg[2] == "true" or arg[2] == "yes") then
				map:setSetting("vehicleweapons", "true")
				scriptMsg("Vehicle weapons will be enabled in the next round!")
			elseif(arg[2] == "false" or arg[2] == "no") then
				map:setSetting("vehicleweapons", "false")
				scriptMsg("Vehicle weapons will be disabled in the next round!")
			else
				map:setSetting("vehicleweapons", nil)
				scriptMsg("Vehicle weapons will not be set in the next round!")
			end
		end
	else privMsg(source, "Usage: %s", arg[1].." <true/false/auto>") end
end

CmdRegister("setmapvehwep", CmdSetMapVehicleWeapons, "resource.rafalh.setmapvehwep")
CmdRegisterAlias("smvehwep", "setmapvehwep")

local function CmdSetMapHunterMinigun(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			if(arg[2] == "true" or arg[2] == "yes") then
				map:setSetting("hunterminigun", "true")
				scriptMsg("Hunter minigun will be enabled in the next round!")
			elseif(arg[2] == "false" or arg[2] == "no") then
				map:setSetting("hunterminigun", "false")
				scriptMsg("Hunter minigun will be disabled in the next round!")
			else
				map:setSetting("hunterminigun", nil)
				scriptMsg("Hunter minigun will be set to auto in the next round!")
			end
		end
	else privMsg(source, "Usage: %s", arg[1].." <true/false/auto>") end
end

CmdRegister("setmaphuntermg", CmdSetMapHunterMinigun, "resource.rafalh.setmaphuntermg")
CmdRegisterAlias("smhuntermg", "setmaphuntermg")
CmdRegisterAlias("smhuntmg", "setmaphuntermg")

local function CmdSetMapWaveHeight(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			local h = tonumber(arg[2])
			if(h) then
				map:setSetting("waveheight", h)
				scriptMsg("Wave height will be set to %.1f in the next round!", h)
			else
				map:setSetting("waveheight", nil)
				scriptMsg("Wave height will set to auto in the next round!")
			end
		end
	else privMsg(source, "Usage: %s", arg[1].." <num/auto>") end
end

CmdRegister("setmapwaveheight", CmdSetMapWaveHeight, "resource.rafalh.setmapwaveheight")
CmdRegisterAlias("smwaveh", "setmapwaveheight")

local function CmdVehicleWeapons(message, arg)
	local res = getResourceFromName("race")
	if(res) then
		local old_enabled, enabled = get("*race.vehicleweapons")
		if(not g_OldVehicleWeapons) then
			g_OldVehicleWeapons = old_enabled
		end
		if(old_enabled == "false") then
			enabled = "true"
			customMsg(0, 255, 0, "Vehicle weapons enabled by %s!", getPlayerName(source))
		else
			enabled = "false"
			customMsg(255, 0, 0, "Vehicle weapons disabled by %s!", getPlayerName(source))
		end
		set("*race.vehicleweapons", enabled)
		triggerEvent("onSettingChange", getResourceRootElement(res), "vehicleweapons", g_OldVehicleWeapons, enabled)
	end
end

CmdRegister("vehicleweapons", CmdVehicleWeapons, "resource.rafalh.vehicleweapons")
CmdRegisterAlias("vehwep", "vehicleweapons")

local function CmdSetMapCompMode(message, arg)
	if(#arg >= 2) then
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		
		if(map) then
			if(arg[2] == "true" or arg[2] == "yes") then
				map:setSetting("compmode", "true")
				scriptMsg("Compatibility mode will be enabled in the next round!")
			else
				map:setSetting("compmode", nil)
				scriptMsg("Compatibility mode will be disabled in the next round!")
			end
		end
	else privMsg(source, "Usage: %s", arg[1].." <true/false>") end
end

CmdRegister("setcompmode", CmdSetMapCompMode, "resource.rafalh.setcompmode")
CmdRegisterAlias("setcmode", "setcompmode")

local function CmdSetMapMaxSpeed(message, arg)
	local room = Player.fromEl(source).room
	local map = getCurrentMap(room)
	local max_speed = touint(arg[2])
	if(map and (max_speed or arg[2] == "false")) then
		if(max_speed == 0) then
			max_speed = nil
		end
		if(map:setSetting("maxspeed", max_speed)) then
			scriptMsg("Maximal speed will be set to %u in the next round!", max_speed or 0)
		else
			privMsg(source, "Failed to set max speed!")
		end
	else privMsg(source, "Usage: %s", arg[1].." <maxspeed>") end
end

CmdRegister("setmapmaxspeed", CmdSetMapMaxSpeed, "resource.rafalh.setmapmaxspeed")

local function GenMapResName(map)
	local name = map:getName()
	if(name:sub(1, 5) ~= "race-") then
		name = "race-"..name
	end
	name = name:gsub("[^a-zA-Z0-9%[%]-]+", "")
	name = name:gsub("-+", "-")
	return name
end

local function FixMapResName(map)
	local map_res_name = getResourceName(map.res)
	local new_map_res_name = GenMapResName(map)
	
	if(map_res_name == new_map_res_name) then
		return 0, "Name is already ok"
	end
	
	local res = getResourceFromName(new_map_res_name)
	if(res and res ~= map.res) then
		return -1, "Name is already used by other resource("..map_res_name.." -> "..new_map_res_name..")"
	end
	
	if(map_res_name:lower() == new_map_res_name:lower()) then
		if(not renameResource(map_res_name, "_"..map_res_name) and
			not renameResource("_"..map_res_name, new_map_res_name)) then
			return -1, "renameResource failed"
		end
	else
		if(not renameResource(map_res_name, new_map_res_name)) then
			return -1, "renameResource failed"
		end
	end
	
	DbQuery("UPDATE rafalh_maps SET name=? WHERE name=?", new_map_res_name, map_res_name)
	
	return 1, "Renamed "..map_res_name.." to "..new_map_res_name
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
			privMsg(player, i.."/"..maps:getCount())
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

local function CmdFixMapResName(msg, arg)
	if(arg[2] == "all") then
		if(g_FixMapResNameTimer) then return end
		
		local co = coroutine.create(FixAllMapsResName)
		coroutine.resume(co, source)
		if(coroutine.status(co) ~= "dead") then
			g_FixMapResNameTimer = setTimer(function()
				coroutine.resume(co)
				if(coroutine.status(co) == "dead") then
					killTimer(g_FixMapResNameTimer)
					g_FixMapResNameTimer = false
				end
			end, 100, 0)
		end
	else
		local room = Player.fromEl(source).room
		local map = arg[2] and findMap(msg:sub(arg[1]:len() + 2)) or getCurrentMap(room)
		if(not map) then return end
		
		local ok, status = FixMapResName(map)
		if(ok) then
			privMsg(source, "%s", status)
		else
			privMsg(source, "Failed: %s", status)
		end
	end
end

CmdRegister("fixmapresname", CmdFixMapResName, true)

local function DetectMapType(map)
	local map_res_name = getResourceName(map.res)
	local node = xmlLoadFile(":"..map_res_name.."/meta.xml")
	if(not node) then return false end
	
	local subnode = xmlFindChild(node, "map", 0)
	if(not subnode) then
		xmlUnloadFile(node)
		return false
	end
	
	local src = xmlNodeGetAttribute(subnode, "src")
	xmlUnloadFile(node)
	if(not src) then return false end
	
	local node = xmlLoadFile(":"..map_res_name.."/"..src)
	if(not node) then return false end
	
	local map_type = "DD"
	local children = xmlNodeGetChildren(node)
	for i, subnode in ipairs(children) do
		local tag = xmlNodeGetName(subnode)
		
		if(tag == "checkpoint") then
			map_type = "Race"
			break
		elseif(tag == "racepickup") then
			local attr = xmlNodeGetAttributes(subnode)
			if(attr.type == "vehiclechange" and attr.vehicle == "425") then
				map_type = "DM"
				break
			end
		end
	end
	
	xmlUnloadFile(node)
	return map_type
end

local function CmdFixMapTags(msg, arg)
	local fix = (arg[2] == "fix")
	local count = 0
	
	local maps = getMapsList()
	for i = 1, maps:getCount() do
		local map = maps:get(i)
		local map_name = map:getName()
		
		if(not map_name:match("^%[%w+%] .*$")) then
			count = count + 1
			
			local new_map_name
			local map_type, mapNameWithoutTag = map_name:match("^%[(%w+)%]%s*(.*)$") -- no space
			if(map_type) then -- Add space
				new_map_name = "["..map_type.."] "..mapNameWithoutTag
			else
				map_type = DetectMapType(map)
				new_map_name = map_type and "["..map_type.."] "..map_name
			end
			
			if(fix) then
				if(new_map_name and map:setInfo("name", new_map_name)) then
					privMsg(source, "Fixed: %s", new_map_name)
				else
					privMsg(source, "Failed to fix: %s", map_name)
				end
			else
				privMsg(source, "To do: %s -> %s", map_name, tostring(new_map_name))
			end
		end
	end
	
	privMsg(source, "%d/%d maps %s.", count, maps:getCount(), fix and "fixed" or "detected")
end

CmdRegister("fixmaptags", CmdFixMapTags, true)

local function MocCleanup()
	if(g_OldVehicleWeapons) then
		set("*race.vehicleweapons", g_OldVehicleWeapons)
	end
end

addInitFunc(function()
	addEventHandler("onResourceStop", g_ResRoot, MocCleanup)
end)
