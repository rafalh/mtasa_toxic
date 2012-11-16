local function FixIntegerFields ()
	local rows = DbQuery ("SELECT tbl_name, sql FROM sqlite_master WHERE type='table' AND tbl_name LIKE 'rafalh_%'")
	for i, data in ipairs (rows) do
		-- Fix numeric fields in "rafalh_*" tables (slow)
		
		-- Get array of integer columns
		local columns = {}
		string.gsub (data.sql, "([%w_]+)%s+%a*INT%a*[%s%),]+", function (col) table.insert (columns, col) end)
		
		if (#columns > 0) then
			local query = "UPDATE "..data.tbl_name.." SET "
			for i, col in ipairs (columns) do
				query = query..col.."=CAST("..col.." AS INTEGER),"
			end
			
			query = query:sub (1, query:len () - 1)
			DbQuery (query)
		end
	end
	
	scriptMsg ("Fixed all integer fields!")
end

local function RemoveUnknownPlayers (fix)
	local id_list = {}
	local rows = DbQuery ("SELECT player FROM rafalh_players")
	for i, data in ipairs (rows) do
		table.insert (id_list, data.player)
	end
	
	local id_list_str = table.concat (id_list, ",")
	
	local rows_count = 0
	local tables = { "rafalh_names", "rafalh_rates", "rafalh_besttimes", "rafalh_profiles" }
	for i, table_name in ipairs (tables) do
		local rows = DbQuery ("SELECT player FROM "..table_name.." WHERE player NOT IN ("..id_list_str..")")
		if (rows and #rows > 0) then
			local invalid = {}
			for j, data in ipairs (rows) do
				table.insert (invalid, data.player)
			end
			
			privMsg (source, "Invalid player IDs in "..table_name..": "..table.concat (invalid, ", "))
			
			if (fix) then
				local invalid_str = table.concat (invalid, ",")
				DbQuery ("DELETE FROM "..table_name.." WHERE player IN ("..invalid_str..")")
			end
			
			rows_count = rows_count + #invalid
		end
	end
	
	privMsg (source, "Rows"..(fix and " (fixed)" or "")..": "..rows_count)
end

local function RemoveUnknownTables (fix)
	-- Remove "race maptimes*" tables
	local rows = DbQuery ("SELECT tbl_name, sql FROM sqlite_master WHERE type='table' and tbl_name LIKE 'race maptimes%'")
	local tables_count = 0
	for i, data in ipairs (rows) do
		tables_count = tables_count + 1
		if (fix) then
			if (DbQuery ("DROP TABLE ?", data.tbl_name)) then
				privMsg (source, "Removed "..data.tbl_name..".")
			else
				privMsg (source, "Cannot remove "..data.tbl_name)
			end
		end
	end
	
	privMsg (source, "Tables"..(fix and " (fixed)" or "")..": "..tables_count)
end

local function RemoveTempPlayers (fix)
	local rows = DbQuery ("SELECT count(player) AS c FROM rafalh_players")
	local total_players_count = rows[1].c
	
	local rows = DbQuery ("SELECT player FROM rafalh_players WHERE time_here < 60 AND online=0")
	local players_count = #rows
	if (fix and #rows > 0) then
		local id_list = {}
		for i, data in ipairs (rows) do
			table.insert (id_list, data.player)
		end
		
		local id_list_str = table.concat (id_list, ",")
		DbQuery ("DELETE FROM rafalh_players WHERE player IN ("..id_list_str..")")
		DbQuery ("DELETE FROM rafalh_names WHERE player IN ("..id_list_str..")")
		DbQuery ("DELETE FROM rafalh_rates WHERE player IN ("..id_list_str..")")
		DbQuery ("DELETE FROM rafalh_besttimes WHERE player IN ("..id_list_str..")")
		DbQuery ("DELETE FROM rafalh_profiles WHERE player IN ("..id_list_str..")")
	end
	
	privMsg (source, "Players"..(fix and " (fixed)" or "")..": "..players_count.."/"..total_players_count)
end

local function RemoveUnknownMaps (fix)
	local rows = DbQuery ("SELECT count(map) AS c FROM rafalh_maps")
	local total_maps_count = rows[1].c
	
	local rows = DbQuery ("SELECT map, name FROM rafalh_maps")
	local unknown_maps = {}
	for i, data in ipairs (rows) do
		if (not getResourceFromName (data.name)) then
			table.insert (unknown_maps, data.map)
		end
	end
	
	if (fix and #unknown_maps > 0) then
		local unknown_maps_str = table.concat (unknown_maps, ",")
		DbQuery ("DELETE FROM rafalh_maps WHERE map IN ("..unknown_maps_str..")")
		DbQuery ("DELETE FROM rafalh_besttimes WHERE map IN ("..unknown_maps_str..")")
		DbQuery ("DELETE FROM rafalh_rates WHERE map IN ("..unknown_maps_str..")")
	end
	
	privMsg (source, "Maps"..(fix and " (fixed)" or "")..": "..#unknown_maps.."/"..total_maps_count)
end

local function RecalcTopTimesCount ()
	DbQuery ("UPDATE rafalh_players SET toptimes_count=0")
	
	local rows = DbQuery ("SELECT map FROM rafalh_maps")
	for i, data in ipairs (rows) do
		local rows2 = DbQuery ("SELECT player FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT 3", data.map)
		for j, data2 in ipairs (rows2) do
			DbQuery ("UPDATE rafalh_players SET toptimes_count=toptimes_count+1 WHERE player=?", data2.player)
		end
	end
	
	scriptMsg ("Finished updating top times statistics!")
end

local function CmdCleanDb (message, arg)
	local fix = arg[2]
	
	RemoveUnknownPlayers (fix == "players")
	RemoveUnknownTables (fix == "tables")
	RemoveTempPlayers (fix == "tempplayers")
	RemoveUnknownMaps (fix == "maps")
	if (fix == "int") then
		FixIntegerFields ()
	end
	if (fix == "vacuum") then
		DbQuery ("VACUUM")
		scriptMsg ("Optimized database!")
	end
	if (fix == "toptimes") then
		RecalcTopTimesCount ()
	end
	
	if (not fix) then
		scriptMsg ("This is a report. Execute "..arg[1].." <players/tables/tempplayers/maps/int/vacuum/toptimes> to actualy clean the database.")
	end
end

CmdRegister ("cleandb", CmdCleanDb, "resource.rafalh.cleandb")
