local function FixAllMapsScripts(worker)
	local map = worker.ctx.maps:get(worker.index)	
	local status = MapPatcher.processMap(map)
	if(status) then
		worker.ctx.count = worker.ctx.count + 1
	end
end

local g_FixMapScriptsWorker = false

local function CmdFixMapScripts (message, arg)
	if (arg[2] == 'all') then
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
		if (map and MapPatcher.processMap(map)) then
			privMsg (source, "Fixed map scripts.")
		else
			privMsg (source, "Nothing to fix...")
		end
	end
end

CmdRegister('fixmapscripts', CmdFixMapScripts, 'resource.'..g_ResName..'.fixmapscripts')

local function CountSpInMapFile(path)
	local node = xmlLoadFile(path)
	if(not node) then return false end
	
	local ret = 0
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local tag = xmlNodeGetName(subnode)
		if(tag == 'spawnpoint') then
			ret = ret + 1
		end
	end
	xmlUnloadFile(node)
	return ret
end

local function CheckMapSpawnpointsCount(map, player, opts)
	local gm = map:getSetting('ghostmode')
	if(tobool(gm)) then return true end -- map has ghostmode, so low spawnpoints count is ok
	
	local mapPath = map:getPath()
	local node = xmlLoadFile(mapPath..'/meta.xml')
	if(not node) then
		outputDebugString('Failed to open '..mapPath..'/meta.xml', 2)
		return false
	end
	
	gm = getMetaSetting(node, 'ghostmode') -- getSetting returns cached value so check real setting
	if(tobool(gm)) then return true end -- if gamemode is enabled, exit
	
	local cnt = 0
	local children = xmlNodeGetChildren(node)
	for i, subnode in ipairs(children) do
		local tag = xmlNodeGetName(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		
		if(tag == 'map' and attr.src) then
			local path = mapPath..'/'..attr.src
			local curFileCnt = CountSpInMapFile(path)
			if(curFileCnt) then
				cnt = cnt + curFileCnt
			else
				outputDebugString('CountSpInMapFile failed for '..path, 2)
			end
		end
	end
	
	if(cnt < 20) then
		privMsg(player, "Map %s has only %u spawn-points", map:getName(), cnt)
		
		if(opts == 'enablegm') then
			setMetaSetting(node, 'ghostmode', 'true')
			xmlSaveFile(node)
		elseif(opts == 'moveres' and map.res) then
			local resName = getResourceName(map.res)
			renameResource(resName, resName, '[maps_to_fix]')
		end
	end
	
	xmlUnloadFile(node)
	return true
end

local function CheckSpCountInMaps(worker)
	local map = worker.ctx.maps:get(worker.index)	
	if(worker.ctx.pattern == '*' or map:getName():find(worker.ctx.pattern, 1, true)) then
		local status = CheckMapSpawnpointsCount(map, worker.info.player, worker.ctx.opts)
		if(status) then
			worker.ctx.count = worker.ctx.count + 1
		end
	end
end

local g_CheckSpWorker = false

local function CmdCheckSp(message, arg)
	local pattern, opts
	if(arg[2] == 'enablegm' or arg[2] == 'moveres') then
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
		privMsg(source, "Started counting spawn-points...")
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

CmdRegister('checksp', CmdCheckSp, 'resource.'..g_ResName..'.checksp')
