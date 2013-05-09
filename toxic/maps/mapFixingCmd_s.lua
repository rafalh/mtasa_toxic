-----------
-- UTILS --
-----------

local function fileGetContents (path)
	local file = fileOpen (path, true)
	if (not file) then
		outputDebugString ("Failed to open "..path, 2)
		return false
	end
	
	local size = fileGetSize (file)
	local buf = size > 0 and fileRead (file, size) or ""
	fileClose (file)
	
	return buf
end

local function fileSetContents (path, buf)
	local file = fileCreate (path)
	if (not file) then return false end
	
	fileWrite (file, buf)
	fileClose (file)
end

local function trimStr (str)
	str = str:gsub ("^%s+", "")
	str = str:gsub ("%s+$", "")
	return str
end

local function fileGetMd5 (path)
	local buf = fileGetContents (path)
	if (not buf) then
		return false
	end
	
	return md5 (buf)
end

-----------
-- MUSIC --
-----------

local g_MusicPattern =
	"function%s+startMusic%(%)%s+"..
		"setRadioChannel%(0%)%s+"..
		"song%s+=%s+playSound%(\"([^\"]+)\",true%)%s+"..
		"(.*)"..
	"end%s+"..
	"function%s+makeRadioStayOff%(%)%s+"..
		"setRadioChannel%(0%)%s+"..
		"cancelEvent%(%)%s+"..
	"end%s+"..
	"function%s+toggleSong%(%)%s+"..
		"if%s+not%s+songOff%s+then%s+"..
			"setSoundVolume%(song,0%)%s+"..
			"songOff%s+=%s+true%s+"..
			"removeEventHandler%(\"onClientPlayerRadioSwitch\",getRootElement%(%),makeRadioStayOff%)%s+"..
		"else%s+"..
			"setSoundVolume%(song,1%)%s+"..
			"songOff%s+=%s+false%s+"..
			"setRadioChannel%(0%)%s+"..
			"addEventHandler%(\"onClientPlayerRadioSwitch\",getRootElement%(%),makeRadioStayOff%)%s+"..
		"end%s+"..
	"end%s+"..
	"addEventHandler%(\"onClientResourceStart\",getResourceRootElement%(getThisResource%(%)%),startMusic%)%s+"..
	"addEventHandler%(\"onClientPlayerRadioSwitch\",getRootElement%(%),makeRadioStayOff%)%s+"..
	"addEventHandler%(\"onClientPlayerVehicleEnter\",getRootElement%(%),makeRadioStayOff%)%s+"..
	"addCommandHandler%(\"[^\"]+\",toggleSong%)%s+"..
	"bindKey%(\"[^\"]+\",\"down\",\"[^\"]+\"%)"

local g_MusicPattern2 =
	"setRadioChannel%(0%)%s+"..
	"song%s*=%s*playSound%(\"([^\"]+)\",%s*true%)%s+"..
	"bindKey%(\"[^\"]+\",%s*\"down\",%s+"..
		"function%s*%(%)%s+"..
			"setSoundPaused%(song,%s*not%s*isSoundPaused%(song%)%)%s+"..
		"end%s+"..
	"%)"

local g_MusicPattern3 =
	"function%s+mukkestart%(%)%s+"..
		"setRadioChannel%(0%)%s+"..
		"song%s+=%s+playSound%(\"([^\"]+)\",true%)%s+"..
		"(.*)"..
	"end%s+"..
	"function%s+turnradiooff%(%)%s+"..
		"setRadioChannel%(0%)%s+"..
		"cancelEvent%(%)%s+"..
	"end%s+"..
	"function%s+toggleSong%(%)%s+"..
		"if%s+not%s+songOff%s+then%s+"..
			"setSoundVolume%(song,0%)%s+"..
			"songOff%s+=%s+true%s+"..
			"removeEventHandler%(\"onClientPlayerRadioSwitch\",getRootElement%(%),turnradiooff%)%s+"..
		"else%s+"..
			"setSoundVolume%(song,1%)%s+"..
			"songOff%s+=%s+false%s+"..
			"setRadioChannel%(0%)%s+"..
			"addEventHandler%(\"onClientPlayerRadioSwitch\",getRootElement%(%),turnradiooff%)%s+"..
		"end%s+"..
	"end%s+"..
	"addEventHandler%(\"onClientResourceStart\",getResourceRootElement%(getThisResource%(%)%),mukkestart%)%s+"..
	"addEventHandler%(\"onClientPlayerRadioSwitch\",getRootElement%(%),turnradiooff%)%s+"..
	"addEventHandler%(\"onClientPlayerVehicleEnter\",getRootElement%(%),turnradiooff%)%s+"..
	"addCommandHandler%(\"[^\"]+\",toggleSong%)%s+"..
	"bindKey%(\"[^\"]+\",\"down\",\"[^\"]+\"%)"

local g_MusicPattern4 =
	"local%s*MUSIC_PATH%s*=%s*\"([^\"]+)\"%s*"..
	"local%s*g_Root%s*=%s*getRootElement%s*%(%)%s*"..
	"local%s*g_ResRoot%s*=%s*getResourceRootElement%s*%(%)%s*"..
	"local%s*g_Me%s*=%s*getLocalPlayer%s*%(%)%s*"..
	"local%s*g_MusicEnabled%s*=%s*false%s*"..
	"local%s*g_Sound%s*=%s*false%s*"..
	"local%s*function%s*onRadioSwitch%s*%(%s*channel%s*%)%s*"..
		"if%s*%(%s*channel%s*~=%s*0%s*%)%s*then%s*"..
			"cancelEvent%s*%(%)%s*"..
		"end%s*"..
	"end%s*"..
	"local%s*function%s*onPlayerVehicleEnter%s*%(%)%s*"..
		"setRadioChannel%s*%(%s*0%s*%)%s*"..
	"end%s*"..
	"local%s*function%s*toggleMusic%s*%(%)%s*"..
		"if%s*g_MusicEnabled%s*then%s*"..
			"setSoundVolume%s*%(%s*g_Sound,%s*0%s*%)%s*"..
			"g_MusicEnabled%s*=%s*false%s*"..
			"removeEventHandler%s*%(%s*\"onClientPlayerRadioSwitch\",%s*g_Root,%s*onRadioSwitch%s*%)%s*"..
			"removeEventHandler%s*%(%s*\"onClientPlayerVehicleEnter\",%s*g_Me,%s*onPlayerVehicleEnter%s*%)%s*"..
		"else%s*"..
			"setSoundVolume%s*%(%s*g_Sound,%s*1%s*%)%s*"..
			"g_MusicEnabled%s*=%s*true%s*"..
			"setRadioChannel%s*%(%s*0%s*%)%s*"..
			"addEventHandler%s*%(%s*\"onClientPlayerRadioSwitch\",%s*g_Root,%s*onRadioSwitch%s*%)%s*"..
			"addEventHandler%s*%(%s*\"onClientPlayerVehicleEnter\",%s*g_Me,%s*onPlayerVehicleEnter%s*%)%s*"..
		"end%s*"..
	"end%s*"..
	"local%s*function%s*init%s*%(%)%s*"..
		"g_Sound%s*=%s*playSound%s*%(%s*MUSIC_PATH,%s*true%s*%)%s*"..
		"if%s*%(%s*g_Sound%s*%)%s*then%s*"..
			"toggleMusic%s*%(%)%s*"..
			"outputChatBox%s*%(%s*[^%)]+%)%s*"..
		"else%s*"..
			"outputDebugString%s*%(%s*\"playSound%s*failed!\",%s*2%s*%)%s*"..
		"end%s*"..
	"end%s*"..
	"addEventHandler%s*%(%s*\"onClientResourceStart\",%s*g_ResRoot,%s*init%s*%)%s*"..
	"addCommandHandler%s*%(%s*\"music\",%s*toggleMusic%s*%)%s*"..
	"bindKey%s*%(%s*\"m\",%s*\"down\",%s*toggleMusic%s*%)"

local function MusicPreprocess (ctx)
	for path, node in pairs (ctx.files) do
		local ext = path:match ("%.(%w+)$")
		if (ext == "mp3") then
			return true
		end
	end
	
	--outputDebugString ("No music has been found in meta.xml", 3)
	return false
end

local function MusicFixClientScript (path, ctx)
	--outputDebugString ("Processing "..path, 3)
	
	local abs_path = ctx.mapPath.."/"..path
	local buf = fileGetContents (abs_path)
	if (not buf) then
		return false
	end
	
	if (buf:byte () == 0x1B) then
		-- binary LUA chunk
		return false
	end
	
	-- Remove music loader
	local buf2 = buf
	--if (buf2:match (g_TestPattern)) then
	--	outputChatBox ("MATCHED")
	--end
	if (not ctx.music_path) then
		local f = function (path, opt_code)
			local isUrl = (path:sub(1, 7) == "http://")
			local isValidPath = isUrl or (ctx.files[path] or ctx.client_scripts[path])
			if(not isValidPath or ctx.music_path) then
				outputDebugString ("Invalid music "..path.." in "..ctx.mapPath, 2)
				return false
			end
			
			ctx.music_path = path
			return trimStr (opt_code or "")
		end
		buf2 = buf2:gsub (g_MusicPattern, f)
		buf2 = buf2:gsub (g_MusicPattern2, f)
		buf2 = buf2:gsub (g_MusicPattern3, f)
		buf2 = buf2:gsub (g_MusicPattern4, f)
	end
	
	-- Yes, I found such scripts :D
	buf2 = buf2:gsub ("addEventHandler%s*%(%s*\"onClientResourceStop\"%s*,%s*getResourceRootElement%s*%(%s*getThisResource%s*%(%s*%)%s*%)%s*,%s*startMusic%s*%)", "")
	buf2 = buf2:gsub ("outputChatBox%s*%(%s*\"[^\"]*Turn[^\"]*Music[^\"]*\"[^%)]*%)", "")
	buf2 = buf2:gsub ("outputChatBox%s*%(%s*\"[^\"]*Toggle[^\"]*music[^\"]*\"[^%)]*%)", "")
	buf2 = buf2:gsub ("outputChatBox%s*%(%s*\"[^\"]*Press[^\"]*turn[^\"]*music[^\"]*\"[^%)]*%)", "")
	buf2 = buf2:gsub ("outputChatBox%s*%(%s*\"[^\"]*Press[^\"]*toggle[^\"]*music[^\"]*\"[^%)]*%)", "")
	buf2 = buf2:gsub ("outputChatBox%s*%(%s*\"[^\"]*Press[^\"]*Song[^\"]*\"[^%)]*%)", "")
	buf2 = buf2:gsub ("outputChatBox%s*%(%s*\"[^\"]*Press[^\"]*music[^\"]*\"[^%)]*%)", "")
	
	if (buf2 == buf) then return true end
	
	-- Create backup
	fileSetContents (abs_path..".bak", buf)
	
	if (buf2:match ("^%s*$")) then
		-- Remove empty file
		fileDelete (abs_path)
		local node = ctx.client_scripts[path]
		ctx.client_scripts[path] = nil
		xmlDestroyNode (node)
	else
		fileSetContents (abs_path, buf2)
	end
	
	return true
end

local function MusicFix (ctx)
	ctx.music_path = false
	for path, node in pairs (ctx.client_scripts) do
		MusicFixClientScript (path, ctx)
	end
	
	if (not ctx.music_path) then
		--outputDebugString ("No music has been found in scripts", 3)
		return false
	end
	
	local music_node = ctx.files[ctx.music_path] or ctx.client_scripts[ctx.music_path]
	if(music_node) then -- may be URL
		xmlNodeSetName(music_node, "html")
		xmlNodeSetAttribute(music_node, "raw", "true")
	end
	setMetaSetting(ctx.node, "music", ctx.music_path)
	
	return true
end

local g_MusicPlugin = {
	preprocess = MusicPreprocess,
	fix = MusicFix }

--------------------
-- PUMA MARKERS 2 --
--------------------

local g_PumaMarkers2Checksums = {
	["FC85F47F45497FF2335BD0DF69A11136"] = true, -- 2.0
	["EFCD5C020334DFFBC3708F92765BFB34"] = true, -- 2.1
	["DA7FD66C5DCCB14028A8A0E6C0C8F3F0"] = true } -- 2.2

local function PumaMarkers2Preprocess (ctx)
	local filename
	if (ctx.client_scripts["Puma-Markers.compiled.lua"]) then
		filename = "Puma-Markers.compiled.lua"
	elseif (ctx.client_scripts["Puma-Markers.lua"]) then
		filename = "Puma-Markers.lua"
	elseif (ctx.client_scripts["PumaMarkers.lua"]) then
		filename = "PumaMarkers.lua"
	elseif(ctx.includes["pumamarkers2"] and not ctx.sync_map_element_data) then
		-- Sync map data for PumaMarkers maps
		return true
	else
		return false
	end
	
	ctx.puma_markers2 = filename
	local path = ctx.mapPath.."/"..filename
	local checksum = fileGetMd5 (path)
	if (not g_PumaMarkers2Checksums[checksum]) then
		return false
	end
	
	return true
end

local function PumaMarkers2Fix (ctx)
	if(not ctx.puma_markers2) then
		return false
	end
	
	-- Always sync map elements data for PumaMarkers
	if(not ctx.sync_map_element_data) then
		ctx.sync_map_element_data = xmlCreateChild (ctx.node, "sync_map_element_data")
	end
	xmlNodeSetValue(ctx.sync_map_element_data, "true")
	
	--outputDebugString ("Fixing Puma Markers 2", 3)
	local script_node = ctx.client_scripts[ctx.puma_markers2]
	assert (script_node)
	xmlDestroyNode (script_node)
	ctx.client_scripts[ctx.puma_markers2] = nil
	local abs_path = ctx.mapPath.."/"..ctx.puma_markers2
	fileDelete(abs_path)
	
	local node = xmlCreateChild(ctx.node, "include")
	xmlNodeSetAttribute(node, "resource", "pumamarkers2")
	
	for path, node in pairs(ctx.files) do
		if(path:match ("Icons/%w+%.png")) then
			xmlDestroyNode(node)
			ctx.files[path] = nil
			
			local abs_path = ctx.mapPath.."/"..path
			fileDelete(abs_path)
		end
	end
	
	return true
end

local g_PumaMarkers2Plugin = {
	preprocess = PumaMarkers2Preprocess,
	fix = PumaMarkers2Fix }

------------
-- CLOUDS --
------------

local function CloudsPreprocess (ctx)
	return not table.empty (ctx.client_scripts)
end

local function CloudsFix (ctx)
	local status = false
	
	for path, node in pairs (ctx.client_scripts) do
		local abs_path = ctx.mapPath.."/"..path
		local buf = fileGetContents (abs_path)
		if (buf) then
			local n1, n2
			buf, n1 = buf:gsub ("SetClouds?Enabled", "setCloudsEnabled")
			buf, n2 = buf:gsub ("setClouds?Enabled", "setCloudsEnabled")
			if (n1 + n2 > 0) then
				if (fileSetContents (abs_path, buf)) then
					status = true
				end
			end
		end
	end
	
	return status
end

local g_CloudsPlugin = {
	preprocess = CloudsPreprocess,
	fix = CloudsFix }

local function CsmPreprocess(ctx)
	if(ctx.client_scripts["CSM.lua"] and not ctx.sync_map_element_data) then
		return true
	end
	return false
end

local function CsmFix(ctx)
	if (not ctx.client_scripts["CSM.lua"]) then return false end
	
	-- Always sync map elements data for CSM
	if(not ctx.sync_map_element_data) then
		ctx.sync_map_element_data = xmlCreateChild (ctx.node, "sync_map_element_data")
	end
	if(xmlNodeGetValue(ctx.sync_map_element_data) == "true") then return false end
	
	return xmlNodeSetValue(ctx.sync_map_element_data, "true")
end

local g_CsmPlugin = {
	preprocess = CsmPreprocess,
	fix = CsmFix }

-------------
-- GENERAL --
-------------

local g_Plugins = { g_MusicPlugin, g_PumaMarkers2Plugin, g_CloudsPlugin, g_CsmPlugin }

local function FixMapScripts (map)
	local ctx = {}
	ctx.mapPath = map:getPath()
	ctx.node = xmlLoadFile (ctx.mapPath.."/meta.xml")
	if (not ctx.node) then return false end
	
	local changed = false
	
	ctx.client_scripts = {}
	ctx.server_scripts = {}
	ctx.files = {}
	ctx.includes = {}
	
	local children = xmlNodeGetChildren (ctx.node)
	for i, subnode in ipairs (children) do
		local tag = xmlNodeGetName (subnode)
		local attr = xmlNodeGetAttributes (subnode)
		
		if (tag == "script" and attr.src) then
			if (attr.type == "client") then
				ctx.client_scripts[attr.src] = subnode
			else
				ctx.server_scripts[attr.src] = subnode
				
				-- Fix wrong type parameter
				if(attr.type and attr.type ~= "server") then
					xmlNodeSetAttribute(subnode, "type", "server")
					changed = true
				end
			end
		elseif (tag == "file" and attr.src) then
			ctx.files[attr.src] = subnode
		elseif (tag == "sync_map_element_data") then
			ctx.sync_map_element_data = subnode
		elseif (tag == "include" and attr.resource) then
			ctx.includes[attr.resource] = subnode
		end
	end
	
	local found = false
	for i, plugin in ipairs (g_Plugins) do
		if (plugin.preprocess and plugin.preprocess (ctx)) then
			found = true
		end
	end
	
	if (found) then
		for i, plugin in ipairs (g_Plugins) do
			if (plugin.fix (ctx)) then
				changed = true
			end
		end
	end
	
	if (changed) then
		xmlSaveFile (ctx.node)
	end
	
	xmlUnloadFile (ctx.node)
	return changed
end

local function FixAllMapsScripts(worker)
	local map = worker.ctx.maps:get(worker.index)	
	local status = FixMapScripts(map)
	if(status) then
		worker.ctx.count = worker.ctx.count + 1
	end
end

local g_FixMapScriptsWorker = false

local function CmdFixMapScripts (message, arg)
	if (arg[2] == "all") then
		if (g_FixMapScriptsWorker) then return end
		
		local maps = getMapsList()
		g_FixMapScriptsWorker = Worker.create{
			fnWork = FixAllMapsScripts,
			player = source,
			count = maps:getCount(),
			fnFinish = function(worker, dt)
				privMsg(worker.info.player, "Finished in %u ms: %u/%u maps processed.", dt, worker.ctx.count, worker.info.count)
				g_FixMapScriptsWorker = false
			end,
		}
		g_FixMapScriptsWorker.ctx.maps = maps
		g_FixMapScriptsWorker.ctx.count = 0
		privMsg(source, "Started fixing all maps...")
		g_FixMapScriptsWorker:start()
	else
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		if (map and FixMapScripts(map)) then
			privMsg (source, "Fixed map scripts.")
		else
			privMsg (source, "Nothing to fix...")
		end
	end
end

CmdRegister("fixmapscripts", CmdFixMapScripts, true)

local function CountSpInMapFile(path)
	local node = xmlLoadFile(path)
	if(not node) then return false end
	
	local ret = 0
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local tag = xmlNodeGetName(subnode)
		if(tag == "spawnpoint") then
			ret = ret + 1
		end
	end
	xmlUnloadFile(node)
	return ret
end

local function CheckMapSpawnpointsCount(map, player, opts)
	local gm = map:getSetting("ghostmode")
	if(tobool(gm)) then return true end -- map has ghostmode, so low spawnpoints count is ok
	
	local mapPath = map:getPath()
	local node = xmlLoadFile(mapPath.."/meta.xml")
	if(not node) then
		outputDebugString("Failed to open "..mapPath.."/meta.xml", 2)
		return false
	end
	
	gm = getMetaSetting(node, "ghostmode") -- getSetting returns cached value so check real setting
	if(tobool(gm)) then return true end -- if gamemode is enabled, exit
	
	local cnt = 0
	local children = xmlNodeGetChildren(node)
	for i, subnode in ipairs(children) do
		local tag = xmlNodeGetName(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		
		if(tag == "map" and attr.src) then
			local path = mapPath.."/"..attr.src
			local curFileCnt = CountSpInMapFile(path)
			if(curFileCnt) then
				cnt = cnt + curFileCnt
			else
				outputDebugString("CountSpInMapFile failed for "..path, 2)
			end
		end
	end
	
	if(cnt < 20) then
		privMsg(player, "Map %s has only %u spawnpoints", map:getName(), cnt)
		
		if(opts == "enablegm") then
			setMetaSetting(node, "ghostmode", "true")
			xmlSaveFile(node)
		elseif(opts == "moveres" and map.res) then
			local resName = getResourceName(map.res)
			renameResource(resName, resName, "[maps_to_fix]")
		end
	else
		--privMsg(player, "Map %s has %u spawnpoints", map:getName(), cnt)
	end
	
	xmlUnloadFile(node)
	return true
end

local function CheckSpCountInMaps(worker)
	local map = worker.ctx.maps:get(worker.index)	
	if(worker.ctx.pattern == "*" or map:getName():find(worker.ctx.pattern, 1, true)) then
		local status = CheckMapSpawnpointsCount(map, worker.info.player, worker.ctx.opts)
		if(status) then
			worker.ctx.count = worker.ctx.count + 1
		end
	end
end

local g_CheckSpWorker = false

local function CmdCheckSp(message, arg)
	local pattern, opts
	if(arg[2] == "enablegm" or arg[2] == "moveres") then
		opts = arg[2]
		pattern = message:sub(arg[1]:len() + 3 + arg[2]:len())
	else
		pattern = message:sub(arg[1]:len() + 2)
	end
	
	if(pattern) then
		if(g_CheckSpWorker) then return end
		
		local maps = getMapsList()
		g_CheckSpWorker = Worker.create{
			fnWork = CheckSpCountInMaps,
			player = source,
			count = maps:getCount(),
			fnFinish = function(worker, dt)
				privMsg(worker.info.player, "Finished in %u ms: %u/%u maps processed.", dt, worker.ctx.count, worker.info.count)
				g_CheckSpWorker = false
			end,
		}
		g_CheckSpWorker.ctx.maps = maps
		g_CheckSpWorker.ctx.pattern = pattern
		g_CheckSpWorker.ctx.opts = opts
		g_CheckSpWorker.ctx.count = 0
		privMsg(source, "Started counting spawnpoints...")
		g_CheckSpWorker:start()
	else
		local room = Player.fromEl(source).room
		local map = getCurrentMap(room)
		if(map and not CheckMapSpawnpointsCount(map, source, opts)) then
			privMsg(source, "Nothing to do...")
		else
			privMsg(source, "Checked current map: %s.", map:getName())
		end
	end
end

CmdRegister("checksp", CmdCheckSp, true)