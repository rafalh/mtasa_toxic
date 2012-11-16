local g_Connection = false
local g_BackupsInterval = 0 -- in sec.

function DbStr ( str )
	return "'"..tostring ( str ):gsub ( "'", "''" ).."'"
end

function DbRedefineTable ( table_name, definition )
	local fields = definition:gsub ( "([%w_]+)%s*[^,]+,", "%1," ):gsub ( ",[%s]*([%w_]+)%s+[^,]+", ",%1" )
	if ( definition == fields ) then -- there is no ","
		fields = definition:gsub ( "([%w_]+)[^,]+", "%1" )
	end
	
	-- MTA SUCKS: TRANSACTIONs doesn't work :/
	
	if ( not DbQuery ( "ALTER TABLE "..table_name.." RENAME TO __"..table_name ) ) then
		return false
	end
	
	if ( not DbQuery ( "CREATE TABLE IF NOT EXISTS "..table_name.." ("..definition..")" ) ) then
		DbQuery ( "ALTER TABLE __"..table_name.." RENAME TO "..table_name )
		return false
	end
	
	if ( not DbQuery ( "INSERT INTO "..table_name.." SELECT "..fields.." FROM __"..table_name ) ) then
		--scriptMsg ( "query: ".."INSERT INTO "..table_name.." SELECT "..fields.." FROM __"..table_name )
		DbQuery ( "DROP TABLE "..table_name )
		DbQuery ( "ALTER TABLE __"..table_name.." RENAME TO "..table_name )
		return false
	end
	
	DbQuery ( "DROP TABLE __"..table_name )
	
	return true
end

if ( get ( "private_db" ) == "false" ) then
	DbQuery = executeSQLQuery
	
	function DbInit ()
	end
else
	local g_DbPath = "conf/db.sqlite"
	
	local function fileCopy ( src_path, dest_path )
		local success = false
		local dest_file = fileCreate ( dest_path )
		if ( dest_file ) then
			local src_file = fileOpen ( src_path, true )
			if ( src_file ) then
				while ( not fileIsEOF ( src_file ) ) do
					local buf = fileRead ( src_file, 1024 )
					fileWrite ( dest_file, buf )
				end
				success = true
				fileClose ( src_file )
			end
			
			fileClose ( dest_file )
		end
		
		return success
	end
	
	function DbBackup ()
		-- remove backup if there is too many
		local max_backups = SmGetUInt ( "max_db_backups", 0 )
		if ( max_backups  ) then
			local i = max_backups
			while ( fileExists ( "backups/db"..i..".sqlite" ) ) do
				fileDelete ( "backups/db"..i..".sqlite" )
				i = i + 1
			end
		end
		
		-- rename backups so new file can be the first
		local i = 1
		while ( fileExists ( "backups/db"..i..".sqlite" ) ) do
			i = i + 1
		end
		
		while ( fileExists ( "backups/db"..( i - 1 )..".sqlite" ) ) do
			fileRename ( "backups/db"..( i - 1 )..".sqlite", "backups/db"..i..".sqlite" )
			i = i - 1
		end
		
		-- close connection to database
		destroyElement ( g_Connection )
		
		-- copy database file
		if ( not fileCopy ( g_DbPath, "backups/db1.sqlite" ) ) then
			outputDebugString ( "Failed to copy file", 2 )
		else
			outputServerLog ( "Database backup created" )
		end
		
		-- reconnect
		g_Connection = dbConnect ( "sqlite", g_DbPath )
	end
	
	local function DbAutoBackup ()
		local now = getRealTime ().timestamp
		
		if ( g_BackupsInterval > 1000 and now - SmGetInt ( "backup_timestamp", 0 ) < g_BackupsInterval - 1000 ) then return end
		
		DbBackup ()
		
		SmSet ( "backup_timestamp", now )
	end
	
	local function CmdBackup ()
		DbBackup ()
		privMsg ( source, "Backup saved!" )
	end
	
	function DbInit ()
		g_Connection = dbConnect ( "sqlite", g_DbPath )
		
		g_BackupsInterval = touint ( get ( "db_backup_int" ), 0 ) * 3600 * 24
		outputDebugString ( "Auto backup: "..g_BackupsInterval, 3 )
		if ( g_BackupsInterval > 0 ) then
			setTimer ( DbAutoBackup, 5000, 1 ) -- make backup just after start
			setTimer ( DbAutoBackup, g_BackupsInterval, 0 )
		end
		
		CmdRegister ( "dbbackup", CmdBackup, true )
	end
	
	function DbQuery ( query, ... )
		local qh = dbQuery ( g_Connection, query, ... )
		assert ( qh )
		local result, numrows, errmsg = dbPoll ( qh, -1 )
		
		if ( result ) then
			return result
		end
		
		outputDebugString ( "SQL query failed: "..errmsg, 2 )
		DbgTraceBack ()
		return false
	end
end

--[[Database = {}
Database.__index = Database

function Database.Create()
	local db = {}
	setmetatable(db, Database)
	db.connection = nil
	return db
end

function Database:Query(query, ...)
	return DbQuery(query, ...)
end

function Database:Str(str)
	return "'"..tostring ( str ):gsub ( "'", "''" ).."'"
end
]]
