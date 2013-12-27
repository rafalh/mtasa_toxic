-- Includes
#include 'include/internal_events.lua'

-- Variables
local g_Stats = {}

-- Functions
function StStartSync(idOrEl)
	local force = false
	if(not g_Stats[idOrEl]) then
		g_Stats[idOrEl] = {refs = 0, data = false, valCache = {}}
		force = true
	end
	
	if(g_Stats[idOrEl].refs == 0) then
		--outputDebugString('start sync '..tostring(idOrEl), 2)
		triggerServerInternalEvent($(EV_START_SYNC_REQUEST), g_Me, {stats = idOrEl}, force)
	end
	g_Stats[idOrEl].refs = g_Stats[idOrEl].refs + 1
end

function StStopSync(idOrEl, stopSync)
	local stats = g_Stats[idOrEl]
	if(not stats) then return end
	
	assert(stats.refs > 0)
	stats.refs = stats.refs - 1
	if(stats.refs == 0) then
		--outputDebugString('pause sync '..tostring(idOrEl), 2)
		local req = stopSync and $(EV_STOP_SYNC_REQUEST) or $(EV_PAUSE_SYNC_REQUEST)
		triggerServerInternalEvent(req, g_Me, {stats = idOrEl})
	end
end

function StDeleteIfNotUsed(idOrEl)
	local stats = g_Stats[idOrEl]
	if(stats and stats.refs == 0) then
		g_Stats[idOrEl] = nil
	end
end

function StUpdatePlayTime()
	local now = getRealTime().timestamp
	
	for id, stats in pairs(g_Stats) do
		if(stats.refs > 0 and stats.data) then
			local playTime = stats.data.time_here
			if(stats.data._loginTimestamp) then
				playTime = now - tonumber(stats.data._loginTimestamp) + playTime
			end
			stats.data._playTime = playTime
			stats.valCache.playtime = false
		end
	end
end

function StGet(idOrEl, field)
	local stats = g_Stats[idOrEl]
	if(not stats or not stats.data) then return false end
	if(field) then
		return stats.data[field]
	else
		return stats.data
	end
end

function StGetValCache(idOrEl)
	local stats = g_Stats[idOrEl]
	if(not stats) then return false end
	return stats.valCache
end

function StOnSync(syncTbl)
	-- is it stats sync?
	if(not syncTbl.stats or not syncTbl.stats[2]) then return end
	
	-- check id
	local id = syncTbl.stats[1]
	if(not g_Stats[id] and id ~= g_MyId and id ~= g_Me) then return end
	
	-- create table if not exists
	if(not g_Stats[id]) then
		g_Stats[id] = {refs = 0}
	end
	
	-- update stats
	local stats = g_Stats[id]
	if(not stats.data) then
		stats.data = {}
	end
	for field, val in pairs(syncTbl.stats[2]) do
		stats.data[field] = val
	end
	stats.data._playTime = g_Stats[id].time_here
	stats.valCache = {}
	
	-- update GUI
	for wnd, view in pairs(StatsView.elMap) do
		if(view.id == id) then
			view:update()
		end
	end
end

addInternalEventHandler($(EV_SYNC), StOnSync)
