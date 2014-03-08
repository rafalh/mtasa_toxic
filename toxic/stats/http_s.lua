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
#if(TOP_TIMES) then
	'toptimes_count, '..
#end
	'mapsPlayed, maxWinStreak, achvCount, bidlvl, '..
	'time_here, first_visit, last_visit, online, ip, serial, account'

function getPlayersStats(player, order, desc, limit, start, online)
	-- Validate parameters
	limit = math.min(touint(limit, 20), 20)
	start = touint(start)
	if(order and not tostring(order):match('^[%w_/%*%+-]+$')) then -- check validity of arguments
		return false
	end
	
	-- Prepare conditions
	local cond = {}
	local playerId = touint(player)
	if(playerId) then
		table.insert(cond, 'player='..playerId)
		limit = 1
	elseif(player and player ~= '') then
		table.insert(cond, 'namePlain LIKE '..DbStr('%'..tostring(player)..'%'))
	end
	if(online) then
		if(g_PlayersCount == 0) then
			-- There is no online players
			return {}, 0
		end
		
		local idList = {}
		for el, player in pairs(g_Players) do
			if(player.id) then
				table.insert(idList, player.id)
			end
		end
		table.insert(cond, 'player IN ('..table.concat(idList, ',')..')')
	end
	
	-- Not console
	table.insert(cond, 'serial<>\'0\'')
	
	-- Prepare 'where' string
	local where = ''
	if(#cond > 0) then
		where = ' WHERE '..table.concat(cond, ' AND ')
	end
	
	-- Count players matching specified criteria
	local playersCount
	if(not playerId) then
		local data = DbQuerySingle('SELECT COUNT(*) AS c FROM '..PlayersTable..where)
		playersCount = data.c
	end
	
	-- Build query
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
		for i, data in ipairs(rows) do
			data.rank = StRankFromPoints(data.points)
			data.name = data.name:gsub('#%x%x%x%x%x%x', '')
			data.maxAchvCount = AchvGetCount()
		end
		
		if(not playersCount) then
			playersCount = #rows
		end
	end
	
	return rows, playersCount
end

function getPlayerStats(playerId)
	playerId = touint(playerId)
	if(not playerId) then
		Debug.warn('Wrong id', 2)
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
