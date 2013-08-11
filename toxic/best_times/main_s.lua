
-- Note: '' <> x'' in SQLite

#include 'include/internal_events.lua'

local g_MapInfo = false
local g_TopTimes = false
local g_PlayerTimes = {}

BestTimesTable = Database.Table{
	name = 'besttimes',
	{'player', 'INT UNSIGNED', fk = {'players', 'player'}},
	{'map', 'INT UNSIGNED', fk = {'maps', 'map'}},
	{'time', 'INT UNSIGNED'},
	{'rec', 'INT UNSIGNED', default = 0, fk = {'blobs', 'id'}},
	{'cp_times', 'INT UNSIGNED', default = 0, fk = {'blobs', 'id'}},
	{'timestamp', 'INT UNSIGNED'},
	{'besttimes_idx', unique = {'map', 'time', 'player'}},
	{'besttimes_idx2', unique = {'map', 'player'}},
}

PlayersTable:addColumns{
	{'toptimes_count', 'SMALLINT UNSIGNED', default = 0},
}

function addPlayerTime(player_id, map_id, time)
	local prof = DbgPerf()
	local wasInTop = false
	local now = getRealTime().timestamp
	
	local rows = DbQuery('SELECT time FROM '..BestTimesTable..' WHERE player=? AND map=? LIMIT 1', player_id, map_id)
	local besttime = rows and rows[1]
	if(besttime) then
		if(besttime.time < time) then -- new time is worse
			return -1
		else
			local rows2 = DbQuery('SELECT count(player) AS c FROM '..BestTimesTable..' WHERE map=? AND time<?', map_id, besttime.time)
			wasInTop = (rows2[1].c < 3) -- were we in the top?
			
			DbQuery('UPDATE '..BestTimesTable..' SET time=?, timestamp=? WHERE player=? AND map=?', time, now, player_id, map_id)
		end
	else
		DbQuery('INSERT INTO '..BestTimesTable..' (player, map, time, timestamp) VALUES(?, ?, ?, ?)', player_id, map_id, time, now)
	end
	
	local rows = DbQuery('SELECT count(player) AS c FROM '..BestTimesTable..' WHERE map=? AND time<=?', map_id, time)
	local pos = rows[1].c
	
	if(pos <= 8) then
		if(pos <= 3 and not wasInTop) then -- player joined to the top
			AccountData.create(player_id):add('toptimes_count', 1)
			
			local rows = DbQuery('SELECT player, rec, cp_times FROM '..BestTimesTable..' WHERE map=? ORDER BY time LIMIT 3,1', map_id)
			local data = rows and rows[1]
			if(data) then -- someone left the top
				AccountData.create(data.player):add('toptimes_count', -1)
				DbQuery('DELETE FROM '..BlobsTable..' WHERE id=? OR id=?', data.rec, data.cp_times)
				DbQuery('UPDATE '..BestTimesTable..' SET rec=0, cp_times=0 WHERE player=? AND map=?', data.player, map_id)
			end
		end
		
		BtDeleteCache() -- invalidate cache
	end
	
	prof:cp('addPlayerTime')
	return pos
end

function BtDeleteTimes(cond, ...)
	local rows = DbQuery('SELECT rec, cp_times FROM '..BestTimesTable..' WHERE '..cond, ...)
	local blobs = {}
	for i, row in ipairs(rows) do
		if(row.rec ~= 0) then
			table.insert(blobs, row.rec)
		end
		if(row.cp_times ~= 0) then
			table.insert(blobs, row.cp_times)
		end
	end
	
	DbQuery('DELETE FROM '..BestTimesTable..' WHERE '..cond, ...)
	if(#blobs > 0) then
		local blobsStr = table.concat(blobs, ',')
		DbQuery('DELETE FROM '..BlobsTable..' WHERE id IN (??)', blobsStr)
	end
end

function BtSendMapInfo(room, show, player)
	local prof = DbgPerf()
	local map = getCurrentMap(room)
	if(not map) then return end
	
	local map_id = map:getId()
	
	if(not g_TopTimes) then
		-- this takes long...
		--local start = getTickCount()
		--for i = 1, 100, 1 do
			g_TopTimes = DbQuery(
				'SELECT bt.player, bt.time, p.name '..
				'FROM '..BestTimesTable..' bt '..
				'INNER JOIN '..PlayersTable..' p ON bt.player=p.player '..
				'WHERE bt.map=? ORDER BY time LIMIT 8', map_id)
		--end
		for i, data in ipairs(g_TopTimes) do
			data.time = formatTimePeriod(data.time / 1000)
		end
		--outputDebugString('Toptimes: '..(getTickCount()-start)..' ms', 2)
	end
	
	if(not g_MapInfo) then
		local rows = DbQuery('SELECT played, rates, rates_count FROM '..MapsTable..' WHERE map=? LIMIT 1', map_id)
		g_MapInfo = rows and rows[1]
		g_MapInfo.name = map:getName()
		g_MapInfo.rating = (g_MapInfo.rates_count > 0 and g_MapInfo.rates/g_MapInfo.rates_count) or 0
		g_MapInfo.author = map:getInfo('author')
	end
	
	local players = {player}
	if(not player) then
		players = getElementsByType('player')
	end
	
	local idList = {}
	for i, player in ipairs(players) do
		local pdata = Player.fromEl(player)
		if(pdata and g_PlayerTimes[player] == nil and pdata.id) then
			g_PlayerTimes[player] = false
			table.insert(idList, pdata.id)
		end
	end
	
	local prof2 = DbgPerf(100)
	if(#idList > 0) then
		local rows = DbQuery(
			'SELECT bt1.player, bt1.time, ('..
				'SELECT COUNT(*) FROM '..BestTimesTable..' AS bt2 '..
				'WHERE bt2.map=bt1.map AND bt2.time<=bt1.time) AS pos '..
			'FROM '..BestTimesTable..' bt1 '..
			'WHERE bt1.map=? AND bt1.player IN (??)', map_id, table.concat(idList, ','))
		for i, data in ipairs(rows) do
			local player = Player.fromId(data.player)
			data.time = formatTimePeriod(data.time / 1000)
			g_PlayerTimes[player.el] = data
		end
	end
	
	prof2:cp('retreiving toptimes')
	
	for i, player in ipairs(players) do
		triggerClientInternalEvent(player, $(EV_CLIENT_MAP_INFO), g_Root,
				show, g_MapInfo, g_TopTimes, g_PlayerTimes[player])
	end
	prof:cp('BtSendMapInfo')
end

function BtDeleteCache()
	g_MapInfo = false
	g_TopTimes = false
	g_PlayerTimes = {}
end

local function BtGamemodeMapStop()
	BtDeleteCache()
end

-- race_delay_indicator uses it
function getTopTime(map_res, cp_times)
	assert(map_res and cp_times)
	local map = Map.create(map_res)
	local map_id = map:getId()
	
	local rows
	if(cp_times) then
		rows = DbQuery('SELECT bt.time, b.data AS cp_times FROM '..BestTimesTable..' bt, '..BlobsTable..' b '..
			'WHERE bt.map=? AND b.id=bt.cp_times ORDER BY bt.time LIMIT 1', map_id)
		for i, row in ipairs(rows) do
			assert(row.cp_times:len() > 0)
			if(zlibUncompress) then
				row.cp_times = zlibUncompress(row.cp_times)
			end
			if(not row.cp_times) then
				outputDebugString('Failed to uncompress '..row.cp_times:len(), 2)
				row.cp_times = {}
			end
		end
	end
	
	if(rows and rows[1]) then
		local rows2 = DbQuery('SELECT count(player) AS c FROM '..BestTimesTable..' WHERE time<? AND map=?', rows[1].time, map_id)
		rows[1].rank = rows2[1].c + 1
	end
	
	return rows
end

function BtPrintTimes(room, map_id)
	for player, pdata in pairs(g_Players) do
		if(pdata.room == room and pdata.id) then
			local rows = DbQuery('SELECT time FROM '..BestTimesTable..' WHERE player=? AND map=? LIMIT 1', pdata.id, map_id)
			local data = rows and rows[1]
			if(data) then
				local timeStr = formatTimePeriod(data.time / 1000)
				pdata:addNotify{
					icon = 'best_times/race.png',
					{"Your personal best time: %s", timeStr}}
			end
		end
	end
end

addInitFunc(function()
	addEventHandler('onGamemodeMapStop', g_Root, BtGamemodeMapStop)
end)
