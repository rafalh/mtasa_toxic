-- Includes
#include 'include/internal_events.lua'

-- Variables
local g_Stats = {}

-- Functions
function StStartSync(idOrEl)
	local force = false
	if(not g_Stats[idOrEl]) then
		g_Stats[idOrEl] = {refs = 0, valCache = {}}
		force = true
	end
	
	if(g_Stats[idOrEl].refs == 0) then
		--outputDebugString('start sync '..tostring(idOrEl), 2)
		triggerServerInternalEvent($(EV_START_SYNC_REQUEST), g_Me, {stats = idOrEl}, force)
	end
	g_Stats[idOrEl].refs = g_Stats[idOrEl].refs + 1
end

function StStopSync(idOrEl)
	g_Stats[idOrEl].refs = g_Stats[idOrEl].refs - 1
	if(g_Stats[idOrEl].refs == 0) then
		--outputDebugString('pause sync '..tostring(idOrEl), 2)
		local req = stopSync and $(EV_STOP_SYNC_REQUEST) or $(EV_PAUSE_SYNC_REQUEST)
		triggerServerInternalEvent(req, g_Me, {stats = idOrEl})
	end
end

function StDeleteIfNotUsed(idOrEl)
	if(g_Stats[idOrEl].refs == 0) then
		g_Stats[idOrEl] = nil
	end
end

function StUpdatePlayTime()
	local now = getRealTime().timestamp
	
	for id, stats in pairs(g_Stats) do
		if(stats.refs > 0) then
			local playTime = stats.time_here
			if(stats._loginTimestamp) then
				playTime = now - tonumber(stats._loginTimestamp) + playTime
			end
			stats._playTime = playTime
			stats.valCache.playtime = false
		end
	end
end

function StGet(idOrEl, field)
	local stats = g_Stats[idOrEl]
	if(not stats) then return false end
	if(field) then
		return stats[field]
	else
		return stats
	end
end

function StOnSync(sync_tbl)
	-- is it stats sync?
	if(not sync_tbl.stats or not sync_tbl.stats[2]) then return end
	
	-- check id
	local id = sync_tbl.stats[1]
	if(not g_Stats[id] and id ~= g_MyId and id ~= g_Me) then return end
	
	-- create table if not exists
	if(not g_Stats[id]) then
		g_Stats[id] = {refs = 0}
	end
	
	-- update stats
	for field, val in pairs(sync_tbl.stats[2]) do
		g_Stats[id][field] = val
	end
	g_Stats[id]._playTime = g_Stats[id].time_here
	g_Stats[id].valCache = {}
	
	-- update GUI
	for wnd, view in pairs(StatsView.elMap) do
		if(view.id == id) then
			view:update()
		end
	end
end

addInternalEventHandler($(EV_SYNC), StOnSync)
