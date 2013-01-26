
-- Note: '' <> x'' in SQLite

#include "include/internal_events.lua"

local g_TopTimes = false

function addPlayerTime(player_id, map_id, time)
	if(g_UpdateInProgress) then return end
	
	local top = false
	
	local rows = DbQuery("SELECT time FROM rafalh_besttimes WHERE player=? AND map=? LIMIT 1", player_id, map_id)
	local besttime = rows and rows[1]
	if(besttime) then
		if (besttime.time < time) then -- new time is worse
			return -1
		else
			local rows2 = DbQuery("SELECT count(player) AS c FROM rafalh_besttimes WHERE map=? AND time<?", map_id, besttime.time)
			
			top = (rows2[1].c < 3) -- were we in the top?
			
			local now = getRealTime().timestamp
			DbQuery("UPDATE rafalh_besttimes SET time=?, timestamp=? WHERE player=? AND map=?", time, now, player_id, map_id)
		end
	else
		local now = getRealTime().timestamp
		DbQuery("INSERT INTO rafalh_besttimes (player, map, time, timestamp) VALUES(?, ?, ?, ?)", player_id, map_id, time, now)
	end
	
	local rows = DbQuery("SELECT count(player) AS c FROM rafalh_besttimes WHERE map=? AND time<?", map_id, time)
	local pos = rows[1].c + 1
	
	if(pos <= 3 and not top) then -- player joined to the top
		StSet(player_id, "toptimes_count", StGet(player_id, "toptimes_count") + 1)
		
		local rows = DbQuery("SELECT player FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT 3,1", map_id)
		if(rows and rows[1]) then -- someone left the top
			local pl4_id = rows[1].player
			StSet(pl4_id, "toptimes_count", StGet (pl4_id, "toptimes_count") - 1)
			DbQuery("UPDATE rafalh_besttimes SET rec=x'', cp_times=x'' WHERE player=? AND map=?", pl4_id, map_id)
		end
	end
	
	g_TopTimes = false -- invalidate cache
	
	return pos
end

function BtSendMapInfo(room, show, player)
	local map = getCurrentMap(room)
	if(not map) then return end
	
	local map_id = map:getId()
	local map_name = map:getName()
	
	if(not g_TopTimes) then
		-- this takes long...
		g_TopTimes = DbQuery("SELECT bt.player, bt.time, p.name FROM rafalh_besttimes bt, rafalh_players p WHERE bt.map=? AND bt.player=p.player ORDER BY time LIMIT 8", map_id )
		for i, data in ipairs(g_TopTimes) do
			data.time = formatTimePeriod(data.time / 1000)
		end
	end
	
	local rows = DbQuery("SELECT played, rates, rates_count FROM rafalh_maps WHERE map=? LIMIT 1", map_id)
	local data = rows and rows[1]
	local rating = (data.rates_count > 0 and data.rates/data.rates_count) or 0
	local author = map:getInfo("author")
	triggerClientInternalEvent(player or g_Root, $(EV_CLIENT_MAP_INFO), g_Root, show, map_name, author, data.played, rating, data.rates_count, g_TopTimes)
end

function BtDeleteCache()
	g_TopTimes = false
end

local function BtGamemodeMapStop()
	g_TopTimes = false
end

-- race_delay_indicator uses it
function getTopTime(map_res, cp_times)
	if(g_UpdateInProgress) then return {} end
	
	assert(map_res and cp_times)
	local map = Map.create(map_res)
	local map_id = map:getId()
	
	local rows
	if(cp_times) then
		rows = DbQuery("SELECT cp_times, time FROM rafalh_besttimes WHERE map=? AND length(cp_times)>0 ORDER BY time LIMIT 1", map_id)
		for i, data in ipairs(rows) do
			assert(data.cp_times:len() > 0)
			local buf = data.cp_times
			data.cp_times = zlibUncompress(data.cp_times)
			if(not data.cp_times) then
				outputDebugString("Failed to uncompress "..buf:len(), 2)
				data.cp_times = {}
			end
		end
	end
	
	if(rows and rows[1]) then
		local rows2 = DbQuery("SELECT count(player) AS c FROM rafalh_besttimes WHERE time<? AND map=?", rows[1].time, map_id)
		rows[1].rank = rows2[1].c + 1
	end
	
	return rows
end

function BtPrintTimes(room, map_id)
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room) then
			local rows = DbQuery("SELECT time FROM rafalh_besttimes WHERE player=? AND map=? LIMIT 1", pdata.id, map_id)
			local data = rows and rows[1]
			if(data) then
				local timeStr = formatTimePeriod(data.time / 1000)
				privMsg(player, "Your personal best time: %s", timeStr)
			end
		end
	end
end

addEventHandler("onGamemodeMapStop", g_Root, BtGamemodeMapStop)
