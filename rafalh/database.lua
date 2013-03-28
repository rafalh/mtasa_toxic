local g_Connection, g_Ready = false, false
local g_Config = {}
local SQLITE_DB_PATH = "conf/db.sqlite"

function DbStr(str)
	return "'"..tostring(str):gsub("'", "''").."'"
end

function DbBlob(data)
	local tbl = {}
	for i = 1, data:len() do
		local code = data:byte(i)
		table.insert(tbl, ("%02x"):format(code))
	end
	return "X'"..table.concat(tbl).."'"
end

function DbRedefineTable(table_name, definition)
	local fields = definition:gsub("([%w_]+)%s*[^,]+,", "%1,"):gsub(",[%s]*([%w_]+)%s+[^,]+", ",%1")
	if(definition == fields) then -- there is no ","
		fields = definition:gsub("([%w_]+)[^,]+", "%1")
	end
	
	-- MTA SUCKS: TRANSACTIONs doesn't work :/
	
	if(not DbQuery("ALTER TABLE "..table_name.." RENAME TO __"..table_name)) then
		return false
	end
	
	if(not DbQuery("CREATE TABLE IF NOT EXISTS "..table_name.." ("..definition..")")) then
		DbQuery("ALTER TABLE __"..table_name.." RENAME TO "..table_name)
		return false
	end
	
	if(not DbQuery("INSERT INTO "..table_name.." SELECT "..fields.." FROM __"..table_name)) then
		--scriptMsg ( "query: ".."INSERT INTO "..table_name.." SELECT "..fields.." FROM __"..table_name )
		DbQuery("DROP TABLE "..table_name)
		DbQuery("ALTER TABLE __"..table_name.." RENAME TO "..table_name)
		return false
	end
	
	DbQuery("DROP TABLE __"..table_name)
	
	return true
end

function DbQuery(query, ...)
	local qh = dbQuery(g_Connection, query, ...)
	assert(qh)
	local result, numrows, errmsg = dbPoll(qh, -1)
	
	if(result) then
		return result
	end
	
	outputDebugString("SQL query failed: "..errmsg, 2)
	--outputDebugString("Query: "..query, 2)
	DbgTraceBack()
	return false
end

----------------- SQLite -----------------

local function DbBackupSQLite()
	-- remove backup if there is too many
	local maxBackups = touint(g_Config.maxBackups, 0)
	if(maxBackups > 0) then
		local i = maxBackups
		while(fileExists("backups/db"..i..".sqlite")) do
			fileDelete("backups/db"..i..".sqlite")
			i = i + 1
		end
	end
	
	-- rename backups so new file can be the first
	local i = 1
	while(fileExists("backups/db"..i..".sqlite")) do
		i = i + 1
	end
	
	while(fileExists("backups/db"..(i - 1)..".sqlite")) do
		fileRename("backups/db"..(i - 1)..".sqlite", "backups/db"..i..".sqlite")
		i = i - 1
	end
	
	-- close connection to database
	destroyElement(g_Connection)
	
	-- copy database file
	if(not fileCopy(SQLITE_DB_PATH, "backups/db1.sqlite")) then
		outputDebugString("Failed to copy file", 2)
	else
		outputServerLog("Database backup created")
	end
	
	-- reconnect
	g_Connection = dbConnect("sqlite", SQLITE_DB_PATH)
end

local function DbAutoBackupSQLite()
	local now = getRealTime().timestamp
	
	local backupsInt = touint(g_Config.backupInterval, 0) * 3600 * 24
	if(backupsInt > 1000 and now - SmGetInt("backup_timestamp", 0) < backupsInt - 1000) then return end
	
	outputDebugString("Auto-backup...", 3)
	DbBackupSQLite()
	
	SmSet("backup_timestamp", now)
end

local function DbInitSQLite()
	--fileCopy("backups/db1.sqlite", SQLITE_DB_PATH)
	g_Connection = dbConnect("sqlite", SQLITE_DB_PATH)
	if(not g_Connection) then
		outputDebugString("Failed to connect to SQLite database!", 1)
		return false
	end
	
	local backupsInt = touint(g_Config.backupInterval, 0) * 3600 * 24
	if(backupsInt > 0) then
		setTimer(DbAutoBackupSQLite, 5000, 1) -- make backup just after start
		setTimer(DbAutoBackupSQLite, backupsInt, 0)
	end
	
	CmdRegister("dbbackup", function()
		DbBackupSqlite()
		privMsg(source, "Backup saved!")
	end, true)
	
	return true
end

----------------- MySQL -----------------

local function DbInitMySQL()
	if(not g_Config.host or not g_Config.dbname or not g_Config.username or not g_Config.password) then
		outputDebugString("Required setting for MySQL connection has not been found (host, dbname, username, password)", 1)
		return false
	end
	
	local params = "dbname="..g_Config.dbname..";host="..g_Config.host
	if(g_Config.port) then
		params = params..";port="..g_Config.port
	end
	
	g_Connection = dbConnect("mysql", params, g_Config.username, g_Config.password)
	if(not g_Connection) then
		outputDebugString("Failed to connect to MySQL database!", 1)
		return false
	end
	
	return true
end

----------------- End -----------------

local function DbLoadConfig()
	local node = xmlLoadFile("conf/database.xml")
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local key = xmlNodeGetName(subnode)
		local val = xmlNodeGetValue(subnode)
		if(val and val:len() > 0) then
			g_Config[key] = val
		end
	end
	
	xmlUnloadFile(node)
	return true
end

function DbInit()
	if(not DbLoadConfig()) then
		outputDebugString("Failed to load database config", 1)
		return false
	end
	
	local success = true
	if(g_Config.type == "builtin") then
		DbQuery = executeSQLQuery
	elseif(g_Config.type == "sqlite") then
		success = DbInitSQLite()
	elseif(g_Config.type == "mysql") then
		success = DbInitMySQL()
	else
		outputDebugString("Unknown database type "..tostring(g_Config.type), 1)
		return false
	end
	
	if(success) then
		g_Ready = true
	end
	
	return success
end

function DbIsReady()
	return g_Ready
end
