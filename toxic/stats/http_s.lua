-- Includes
#include 'include/config.lua'

local FIELDS = 'player, name, cash, points, '..
#if(DM_STATS) then
	'dmVictories, huntersTaken, dmPlayed, '..
#end
#if(DD_STATS) then
	'ddVictories, ddPlayed, '..
#end
#if(RACE_STATS) then
	'raceVictories, racesFinished, racesPlayed, '..
#end
	'mapsPlayed, maxWinStreak, toptimes_count, achvCount, bidlvl, '..
	'time_here, first_visit, last_visit, online, ip, serial, account'

function getPlayersStats(player, order, desc, limit, start, online)
	-- Validate parameters
	limit = math.min(touint(limit, 20), 20)
	start = touint(start)
	if(order and not tostring(order):match ( '^[%w_/%*%+-]+$')) then -- check validity of arguments
		return false
	end
	
	-- Build query
	local cond = {'serial<>\'0\''}
	local player_id = touint(player)
	if(player_id) then
		table.insert(cond, 'player='..player_id)
		limit = 1
	elseif(player and player ~= '') then
		table.insert(cond, 'name LIKE '..DbStr('%'..tostring(player)..'%'))
	end
	if(online) then
		table.insert(cond, 'online=1')
	end
	
	local where = ''
	if(#cond > 0) then
		where = ' WHERE '..table.concat(cond, ' AND ')
	end
	
	local players_count
	if(not player_id) then
		local rows = DbQuery('SELECT COUNT(*) AS c FROM '..PlayersTable..where)
		players_count = rows[1].c
	end
	
	local query = 'SELECT '..FIELDS..' FROM '..PlayersTable..where
	if(order) then
		query = query..' ORDER BY '..tostring(order)..((desc and ' DESC') or '')
	end
	query = query..' LIMIT '
	if(start) then
		query = query..start..','
	end
	query = query..limit
	
	-- Query database
	local rows = DbQuery(query)
	if(rows) then
		for i, data in ipairs ( rows ) do
			data.rank = StRankFromPoints ( data.points )
			data.name = data.name:gsub('#%x%x%x%x%x%x', '')
			data.maxAchvCount = AchvGetCount()
		end
		
		if(not players_count) then
			players_count = #rows
		end
	end
	
	return rows, players_count
end

function getPlayerStats(playerId)
	playerId = touint(playerId)
	if(not playerId) then
		outputDebugString('Wrong id', 2)
		return false
	end
	
	local rows = DbQuery('SELECT '..FIELDS..' FROM '..PlayersTable..' WHERE player=?', playerId)
	local data = rows and rows[1]
	return data
end
RPC.allow('getPlayerStats')

addInitFunc(function()
	addEvent('main_onPlayersListReq', true)
	
	addEventHandler('main_onPlayersListReq', g_ResRoot, function(...)
		local rows, cnt = getPlayersStats(...)
		triggerClientEvent(client, 'main_onPlayersList', g_ResRoot, rows, cnt)
	end)
end)
