local function FixIntegerFields()
	local rows = DbQuery("SELECT tbl_name, sql FROM sqlite_master WHERE type='table' AND tbl_name LIKE 'rafalh_%'")
	for i, data in ipairs(rows) do
		-- Fix numeric fields in "rafalh_*" tables (slow)
		
		-- Get array of integer columns
		local columns = {}
		string.gsub(data.sql, "([%w_]+)%s+%a*INT%a*[%s%),]+", function (col) table.insert (columns, col) end)
		
		if(#columns > 0) then
			local query = "UPDATE "..data.tbl_name.." SET "
			for i, col in ipairs (columns) do
				query = query..col.."=CAST("..col.." AS INTEGER),"
			end
			
			query = query:sub(1, query:len () - 1)
			DbQuery(query)
		end
	end
	
	privMsg(source, "Fixed all integer fields!")
end

local function RemoveUnknownPlayers(fix)
	local idList = {}
	local rows = DbQuery("SELECT player FROM rafalh_players")
	for i, data in ipairs(rows) do
		table.insert(idList, data.player)
	end
	
	local idListStr = table.concat(idList, ",")
	
	local rowsCount = 0
	local tables = { "rafalh_names", "rafalh_rates", "rafalh_besttimes", "rafalh_profiles" }
	for i, tblName in ipairs(tables) do
		local rows = DbQuery ("SELECT player FROM "..tblName.." WHERE player NOT IN ("..idListStr..")")
		if(rows and #rows > 0) then
			local invalid = {}
			for j, data in ipairs(rows) do
				table.insert(invalid, data.player)
			end
			
			local invalidStr = table.concat(invalid, ", ")
			privMsg(source, "Invalid player IDs in %s: %s", tblName, invalidStr)
			
			if(fix) then
				DbQuery("DELETE FROM "..tblName.." WHERE player IN ("..invalidStr..")")
			end
			
			rowsCount = rowsCount + #invalid
		end
	end
	
	privMsg(source, "Rows with unknown players"..(fix and " (fixed)" or "")..": %u", rowsCount)
end

local function RemoveUnknownTables(fix)
	-- Remove "race maptimes*" tables
	local rows = DbQuery("SELECT tbl_name FROM sqlite_master WHERE type='table' and tbl_name LIKE 'race maptimes%'")
	local tablesCount = #rows
	if(fix) then
		for i, data in ipairs(rows) do
			if(DbQuery("DROP TABLE ?", data.tbl_name)) then
				privMsg(source, "Removed %s.", data.tbl_name)
			else
				privMsg(source, "Cannot remove %s", data.tbl_name)
			end
		end
	end
	
	privMsg(source, "Tables"..(fix and " (fixed)" or "")..": "..tablesCount)
end

local function RemoveTempPlayers(fix)
	local rows = DbQuery("SELECT count(player) AS c FROM rafalh_players")
	local totalPlayersCount = rows[1].c
	
	local rows = DbQuery("SELECT player FROM rafalh_players WHERE time_here < 60 AND online=0 AND toptimes_count=0")
	local tempPlayersCount = #rows
	if(fix and #rows > 0) then
		local idList = {}
		for i, data in ipairs (rows) do
			table.insert(idList, data.player)
		end
		
		local idListStr = table.concat(idList, ",")
		DbQuery ("DELETE FROM rafalh_players WHERE player IN ("..idListStr..")")
		DbQuery ("DELETE FROM rafalh_names WHERE player IN ("..idListStr..")")
		DbQuery ("DELETE FROM rafalh_rates WHERE player IN ("..idListStr..")")
		DbQuery ("DELETE FROM rafalh_besttimes WHERE player IN ("..idListStr..")")
		DbQuery ("DELETE FROM rafalh_profiles WHERE player IN ("..idListStr..")")
	end
	
	privMsg(source, "Temp players"..(fix and " (fixed)" or "")..": %u/%u", tempPlayersCount, totalPlayersCount)
end

local function RemoveUnknownMaps(fix)
	local rows = DbQuery("SELECT count(map) AS c FROM rafalh_maps")
	local totalMapsCount = rows[1].c
	
	local rows = DbQuery("SELECT map, name FROM rafalh_maps")
	local unkMaps = {}
	for i, data in ipairs (rows) do
		if(not getResourceFromName(data.name)) then
			table.insert(unkMaps, data.map)
		end
	end
	
	if(fix and #unkMaps > 0) then
		for i, mapId in ipairs(unkMaps) do
			-- Decrement Top Times count
			local rows = DbQuery("SELECT player FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT 3", mapId)
			for j, data in ipairs(rows) do
				local accountData = AccountData.create(data.player)
				accountData:add("toptimes_count", -1)
			end
		end
		
		local unkMapsStr = table.concat(unkMaps, ",")
		DbQuery("DELETE FROM rafalh_maps WHERE map IN ("..unkMapsStr..")")
		DbQuery("DELETE FROM rafalh_besttimes WHERE map IN ("..unkMapsStr..")")
		DbQuery("DELETE FROM rafalh_rates WHERE map IN ("..unkMapsStr..")")
	end
	
	privMsg(source, "Unknown maps"..(fix and " (fixed)" or "")..": %u/%u", #unkMaps, totalMapsCount)
end

local function RecalcTopTimesCount()
	DbQuery("UPDATE rafalh_players SET toptimes_count=0")
	
	local rows = DbQuery("SELECT map FROM rafalh_maps")
	for i, data in ipairs (rows) do
		local rows2 = DbQuery("SELECT player FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT 3", data.map)
		for j, data2 in ipairs (rows2) do
			DbQuery("UPDATE rafalh_players SET toptimes_count=toptimes_count+1 WHERE player=?", data2.player)
		end
	end
	
	scriptMsg("Finished updating top times statistics!")
end

local function CheckAchievements(fix)
	local rows = DbQuery("SELECT count(player) AS c FROM rafalh_players")
	local totalPlayersCount = rows[1].c
	local rowsCount = 0
	
	local rows = DbQuery("SELECT player, achievements FROM rafalh_players WHERE achievements<>x''")
	for i, data in ipairs(rows) do
		local achvStr = data.achievements
		local achvList = {string.byte(achvStr, 1, achvStr:len())}
		local achvSet, newAchvStr = {}, ""
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
						"WTF achvCount "..accountData.achvCount.." invalid "..invalidIdCount.." player "..data.player)
					accountData:add("achvCount",  -invalidIdCount)
				end
				
				accountData:set("achievements", newAchvStr)
			end
			rowsCount = rowsCount + 1
		end
	end
	
	privMsg(source, "Achievements count"..(fix and " (fixed)" or "")..": %u/%u", rowsCount, totalPlayersCount)
end

local function CmdCleanDb (message, arg)
	local fix = arg[2]
	
	RemoveUnknownPlayers(fix == "players")
	RemoveUnknownTables(fix == "tables")
	RemoveTempPlayers(fix == "tempplayers")
	RemoveUnknownMaps(fix == "maps")
	if(fix == "int") then
		FixIntegerFields()
	end
	if(fix == "vacuum") then
		DbQuery("VACUUM")
		scriptMsg("Optimized database!")
	end
	if(fix == "toptimes") then
		RecalcTopTimesCount()
	end
	CheckAchievements(fix == "achievements")
	
	if(not fix) then
		scriptMsg("This is a report. Execute "..arg[1].." <players/tables/tempplayers/maps/int/vacuum/toptimes/achievements> to actualy clean the database.")
	end
end

CmdRegister("cleandb", CmdCleanDb, "resource."..g_ResName..".cleandb")
