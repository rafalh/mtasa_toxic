local function FixAllMapsScripts(worker)
	local map = worker.ctx.maps:get(worker.index)	
	local status = MapPatcher.processMap(map)
	if(status) then
		worker.ctx.count = worker.ctx.count + 1
	end
end

local g_FixMapScriptsWorker = false

CmdMgr.register{
	name = 'fixmapscripts',
	accessRight = AccessRight('fixmapscripts'),
	args = {
		{'mapName', type = 'str', defVal = false},
		{'flags', type = 'str', defVal = false},
	},
	func = function(ctx, mapName, flags)
		if(mapName == 'all' or mapName == '*') then
			if(g_FixMapScriptsWorker) then return end
			
			local maps = getMapsList()
			g_FixMapScriptsWorker = Worker.create{
				fnWork = FixAllMapsScripts,
				player = ctx.player.el,
				count = maps:getCount(),
				fnFinish = function(worker, dt)
					privMsg(worker.info.player, "Finished in %u ms: %u/%u maps processed.", dt, worker.ctx.count, worker.info.count)
					g_FixMapScriptsWorker = false
				end,
			}
			g_FixMapScriptsWorker.ctx.maps = maps
			g_FixMapScriptsWorker.ctx.count = 0
			privMsg(ctx.player, "Started fixing all maps...")
			g_FixMapScriptsWorker:start()
		else
			local room = ctx.player.room
			local force = (flags == 'f')
			local map = mapName and findMap(mapName) or getCurrentMap(room)
			if(map and MapPatcher.processMap(map, force)) then
				privMsg(ctx.player, "Fixed map scripts.")
			else
				privMsg(ctx.player, "Nothing to fix...")
			end
		end
	end
}

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
	local metaFile = MetaFile(mapPath..'/meta.xml')
	if(not metaFile:open()) then
		Debug.warn('Failed to open '..mapPath..'/meta.xml')
		return false
	end
	
	gm = metaFile:getSetting('ghostmode') -- map:getSetting returns cached value so check real setting
	if(tobool(gm)) then return true end -- if gamemode is enabled, exit
	
	local cnt = 0
	local children = xmlNodeGetChildren(metaFile.node)
	for i, subnode in ipairs(children) do
		local tag = xmlNodeGetName(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		
		if(tag == 'map' and attr.src) then
			local path = mapPath..'/'..attr.src
			local curFileCnt = CountSpInMapFile(path)
			if(curFileCnt) then
				cnt = cnt + curFileCnt
			else
				Debug.warn('CountSpInMapFile failed for '..path)
			end
		end
	end
	
	if(cnt < 20) then
		privMsg(player, "Map %s has only %u spawn-points", map:getName(), cnt)
		
		if(opts == 'enablegm') then
			metaFile:setSetting('ghostmode', 'true')
			metaFile:save()
			metaFile:close()
		elseif(opts == 'moveres' and map.res) then
			metaFile:close()
			local resName = getResourceName(map.res)
			renameResource(resName, resName, '[maps_to_fix]')
		else
			metaFile:close()
		end
	else
		metaFile:close()
	end
	
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

CmdMgr.register{
	name = 'checksp',
	accessRight = AccessRight('checksp'),
	args = {
		{'mapNamePattern', type = 'str', defVal = false},
		{'action', type = 'str', defVal = false},
	},
	func = function(ctx, mapNamePattern, action)
		if(mapNamePattern) then
			if(g_CheckSpWorker) then return end
			
			local maps = getMapsList()
			g_CheckSpWorker = Worker.create{
				fnWork = CheckSpCountInMaps,
				player = ctx.player.el,
				count = maps:getCount(),
				fnFinish = function(worker, dt)
					privMsg(worker.info.player, "Finished in %u ms: %u/%u maps processed.", dt, worker.ctx.count, worker.info.count)
					g_CheckSpWorker = false
				end,
			}
			g_CheckSpWorker.ctx.maps = maps
			g_CheckSpWorker.ctx.pattern = mapNamePattern
			g_CheckSpWorker.ctx.opts = action
			g_CheckSpWorker.ctx.count = 0
			privMsg(ctx.player, "Started counting spawn-points...")
			g_CheckSpWorker:start()
		else
			local room = ctx.player.room
			local map = getCurrentMap(room)
			if(map and not CheckMapSpawnpointsCount(map, ctx.player.el, action)) then
				privMsg(ctx.player, "Nothing to do...")
			else
				privMsg(ctx.player, "Checked current map: %s.", map:getName())
			end
		end
	end
}
