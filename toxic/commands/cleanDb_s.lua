-- Includes
#include 'include/config.lua'

local function FixIntegerFields()
	local rows = DbQuery('SELECT tbl_name, sql FROM sqlite_master WHERE type=? AND tbl_name LIKE ?', 'table', 'rafalh_%')
	for i, data in ipairs(rows) do
		-- Fix numeric fields in 'rafalh_*' tables (slow)
		
		-- Get array of integer columns
		local columns = {}
		string.gsub(data.sql, '([%w_]+)%s+%a*INT%a*[%s%),]+', function (col) table.insert (columns, col) end)
		
		if(#columns > 0) then
			local query = 'UPDATE '..data.tbl_name..' SET '
			for i, col in ipairs (columns) do
				query = query..col..'=CAST('..col..' AS INTEGER),'
			end
			
			query = query:sub(1, query:len () - 1)
			DbQuery(query)
		end
	end
	
	privMsg(source, "Fixed all integer fields!")
end

local function RemoveUnknownPlayers(fix)
	local idList = {}
	local rows = DbQuery('SELECT player FROM '..PlayersTable)
	for i, data in ipairs(rows) do
		table.insert(idList, data.player)
	end
	
	local idListStr = table.concat(idList, ',')
	
	local rowsCount = 0
	local tables = { NamesTable, RatesTable, BestTimesTable, ProfilesTable }
	for i, tblName in ipairs(tables) do
		local rows = DbQuery ('SELECT player FROM '..tblName..' WHERE player NOT IN ('..idListStr..')')
		if(rows and #rows > 0) then
			local invalid = {}
			for j, data in ipairs(rows) do
				table.insert(invalid, data.player)
			end
			
			local invalidStr = table.concat(invalid, ', ')
			privMsg(source, "Invalid player IDs in %s: %s", tblName, invalidStr)
			
			if(fix) then
				DbQuery('DELETE FROM '..tblName..' WHERE player IN ('..invalidStr..')')
			end
			
			rowsCount = rowsCount + #invalid
		end
	end
	
	privMsg(source, 'Rows with unknown players'..(fix and ' (fixed)' or '')..': %u', rowsCount)
end

local function RemoveUnknownTables(fix)
	-- Remove 'race maptimes*' tables
	local rows = DbQuery('SELECT tbl_name FROM sqlite_master WHERE type=? and tbl_name LIKE ?', 'table', 'race maptimes%')
	local tablesCount = #rows
	if(fix) then
		for i, data in ipairs(rows) do
			if(DbQuery('DROP TABLE ?', data.tbl_name)) then
				privMsg(source, 'Removed %s.', data.tbl_name)
			else
				privMsg(source, 'Cannot remove %s', data.tbl_name)
			end
		end
	end
	
	privMsg(source, 'Tables'..(fix and ' (fixed)' or '')..': '..tablesCount)
end

local function RemoveTempPlayers(fix)
	local rows = DbQuery('SELECT count(player) AS c FROM '..PlayersTable)
	local totalPlayersCount = rows[1].c
	
#if(TOP_TIMES) then
	local rows = DbQuery('SELECT player FROM '..PlayersTable..' WHERE time_here < 60 AND online=0 AND toptimes_count=0')
#else
	local rows = DbQuery('SELECT player FROM '..PlayersTable..' WHERE time_here < 60 AND online=0')
#end
	local tempPlayersCount = #rows
	if(fix and #rows > 0) then
		local idList = {}
		for i, data in ipairs (rows) do
			table.insert(idList, data.player)
		end
		
		local idListStr = table.concat(idList, ',')
		DbQuery ('DELETE FROM '..PlayersTable..' WHERE player IN ('..idListStr..')')
		DbQuery ('DELETE FROM '..NamesTable..' WHERE player IN ('..idListStr..')')
		DbQuery ('DELETE FROM '..RatesTable..' WHERE player IN ('..idListStr..')')
		DbQuery ('DELETE FROM '..BestTimesTable..' WHERE player IN ('..idListStr..')')
		DbQuery ('DELETE FROM '..ProfilesTable..' WHERE player IN ('..idListStr..')')
	end
	
	privMsg(source, 'Temp players'..(fix and ' (fixed)' or '')..': %u/%u', tempPlayersCount, totalPlayersCount)
end

local function RemoveUnknownMaps(fix)
	local rows = DbQuery('SELECT count(map) AS c FROM '..MapsTable)
	local totalMapsCount = rows[1].c
	
	local rows = DbQuery('SELECT map, name FROM '..MapsTable)
	local unkMaps = {}
	for i, data in ipairs (rows) do
		if(not getResourceFromName(data.name)) then
			table.insert(unkMaps, data.map)
		end
	end
	
	if(fix and #unkMaps > 0) then
		local unkMapsStr = table.concat(unkMaps, ',')
		
		if(BestTimesTable) then
			for i, mapId in ipairs(unkMaps) do
				-- Decrement Top Times count
				local rows = DbQuery('SELECT player FROM '..BestTimesTable..' WHERE map=? ORDER BY time LIMIT 3', mapId)
				for j, data in ipairs(rows) do
					local accountData = AccountData.create(data.player)
					accountData:add('toptimes_count', -1)
				end
			end
			
			DbQuery('DELETE FROM '..BestTimesTable..' WHERE map IN ('..unkMapsStr..')')
		end
		
		if(RatesTable) then
			DbQuery('DELETE FROM '..RatesTable..' WHERE map IN ('..unkMapsStr..')')
		end
		
		DbQuery('DELETE FROM '..MapsTable..' WHERE map IN ('..unkMapsStr..')')
	end
	
	privMsg(source, 'Unknown maps'..(fix and ' (fixed)' or '')..': %u/%u', #unkMaps, totalMapsCount)
end

#if(TOP_TIMES) then
local function RecalcTopTimesCount()
	DbQuery('UPDATE '..PlayersTable..' SET toptimes_count=0')
	
	local rows = DbQuery('SELECT map FROM '..MapsTable)
	for i, data in ipairs (rows) do
		local rows2 = DbQuery('SELECT player FROM '..BestTimesTable..' WHERE map=? ORDER BY time LIMIT 3', data.map)
		for j, data2 in ipairs (rows2) do
			DbQuery('UPDATE '..PlayersTable..' SET toptimes_count=toptimes_count+1 WHERE player=?', data2.player)
		end
	end
	
	scriptMsg("Finished updating top times statistics!")
end
#end -- TOP_TIMES

local function CheckAchievements(fix)
	local rows = DbQuery('SELECT count(player) AS c FROM '..PlayersTable..'')
	local totalPlayersCount = rows[1].c
	local rowsCount = 0
	
	local rows = DbQuery('SELECT player, achievements FROM '..PlayersTable..' WHERE achievements<>x\'\'')
	for i, data in ipairs(rows) do
		local achvStr = data.achievements
		local achvList = {string.byte(achvStr, 1, achvStr:len())}
		local achvSet, newAchvStr = {}, ''
		local invalidIdCount = 0
		for j, achvId in ipairs(achvList) do
			if(achvSet[achvId]) then
				invalidIdCount = invalidIdCount + 1
			else
				achvSet[achvId] = true
				if(fix) then
					newAchvStr = newAchvStr..string.char(achvId)
				end
			end
		end
		
		if(invalidIdCount > 0) then
			if(fix) then
				local accountData = AccountData.create(data.player)
				
				if(accountData.achvCount > 0) then
					assert(accountData.achvCount > invalidIdCount,
						'WTF achvCount '..accountData.achvCount..' invalid '..invalidIdCount..' player '..data.player)
					accountData:add('achvCount',  -invalidIdCount)
				end
				
				accountData:set('achievements', newAchvStr)
			end
			rowsCount = rowsCount + 1
		end
	end
	
	privMsg(source, 'Achievements count'..(fix and ' (fixed)' or '')..': %u/%u', rowsCount, totalPlayersCount)
end

CmdMgr.register{
	name = 'cleandb',
	desc = "Cleans script database from garbage",
	accessRight = AccessRight('cleandb'),
	args = {
		{'mode', type = 'string', def = false},
	},
	func = function(ctx, mode)
		RemoveUnknownPlayers(mode == 'players')
		RemoveUnknownTables(mode == 'tables')
		RemoveTempPlayers(mode == 'tempplayers')
		RemoveUnknownMaps(mode == 'maps')
		if(mode == 'int') then
			FixIntegerFields()
		end
		if(mode == 'vacuum') then
			DbQuery('VACUUM')
			scriptMsg("Optimized database!")
		end
	#if(TOP_TIMES) then
		if(mode == 'toptimes') then
			RecalcTopTimesCount()
		end
	#end
		CheckAchievements(mode == 'achievements')
		
		if(not mode) then
			scriptMsg("This is a report. Execute /%s <players/tables/tempplayers/maps/int/vacuum/toptimes/achievements> to actually clean the database.", ctx.cmdName)
		end
	end
}
