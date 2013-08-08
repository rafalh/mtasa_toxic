local g_Connection, g_Ready, g_Driver = false, false, false
local g_Config = {}
local SQLITE_DB_PATH = 'conf/db.sqlite'

Database = {}
Database.tblList = {}
Database.tblMap = {}
Database.Drivers = {}

DbPrefix = ''

function DbStr(str)
	return '\''..tostring(str):gsub('\'', '\'\'')..'\''
end

function DbBlob(data)
	local tbl = {}
	for i = 1, data:len() do
		local code = data:byte(i)
		table.insert(tbl, ('%02x'):format(code))
	end
	return 'X\''..table.concat(tbl)..'\''
end

function DbRecreateTable(tbl)
	--[[local fields = definition:gsub('([%w_]+)%s*[^,]+,', '%1,'):gsub(',[%s]*([%w_]+)%s+[^,]+', ',%1')
	if(definition == fields) then -- there is no ','
		fields = definition:gsub('([%w_]+)[^,]+', '%1')
	end]]
	
	local fields = tbl:getColumnsList()
	local fieldsStr = table.concat(fields, ',')
	
	if(not DbQuery('ALTER TABLE '..tbl..' RENAME TO __'..tbl)) then
		return false
	end
	
	local success = g_Driver:createTable(tbl)
	if(not success) then
		outputDebugString('Failed to recreate '..tbl.name..' table', 1)
		DbQuery('ALTER TABLE __'..tbl..' RENAME TO '..tbl)
		return false
	end
	
	if(not DbQuery('INSERT INTO '..tbl..' SELECT '..fieldsStr..' FROM __'..tbl)) then
		outputDebugString('Failed to copy rows when recreating '..tbl.name, 1)
		DbQuery('DROP TABLE '..tbl)
		DbQuery('ALTER TABLE __'..tbl..' RENAME TO '..tbl)
		return false
	end
	
	DbQuery('DROP TABLE __'..tbl)
	
	return true
end

function DbQuery(query, ...)
	local prof = DbgPerf(100)
	local result = g_Driver and g_Driver:query(query, ...)
	prof:cp('SQL query '..query:sub(1, 255))
	return result
end

function Database.createTable(tbl)
	return g_Driver and g_Driver:createTable(tbl)
end

function Database.getLastInsertID()
	return g_Driver and g_Driver:getLastInsertID()
end

----------------- Database.Table -----------------

Database.Table = {}
Database.Table.__mt = {__index = {}}

function Database.Table.__mt.__index:addColumns(cols)
	for i, col in ipairs(cols) do
		assert(col[1])
		table.insert(self, col)
		self.colMap[col[1]] = col
	end
end

function Database.Table.__mt.__index:insertDefault()
	return g_Driver and g_Driver:insertDefault(self)
end

function Database.Table.__mt.__index:getColumnsList()
	local ret = {}
	for i, col in ipairs(self) do
		if(col[2]) then
			table.insert(ret, col[1])
		end
	end
	return ret
end

function Database.Table:create(args)
	assert(args.name)
	
	local self = setmetatable({}, Database.Table.__mt)
	self.name = args.name
	self.colMap = {}
	self:addColumns(args)
	
	table.insert(Database.tblList, self)
	Database.tblMap[self.name] = self
	return self
end

function Database.Table.__mt:__tostring(tbl)
	return DbPrefix..self.name
end

function Database.Table.__mt.__concat(a, b)
	if(type(a) == 'table') then
		return DbPrefix..a.name..tostring(b)
	else
		return tostring(a)..DbPrefix..b.name
	end
end

setmetatable(Database.Table, {__call = Database.Table.create})

----------------- Common Driver -----------------

Database.Drivers._common = {}
function Database.Drivers._common:getColDef(col, constr)
	local colDef = col[1]..' '..col[2]
	if(not col.null) then
		colDef = colDef..' NOT NULL'
	end
	if(col.default ~= nil) then
		local defVal = col.default
		if(col.null and col.default == false) then
			defVal = 'NULL'
		elseif(col[2]:upper() == 'BLOB') then
			defVal = DbBlob(defVal)
		elseif(type(col.default) == 'string') then
			defVal = DbStr(defVal)
		else
			defVal = tostring(defVal)
		end
		colDef = colDef..' DEFAULT '..defVal
	end
	
	if(col.fk) then
		-- Check it here because when original table is defined foreign table can be not existant
		local foreignTbl = Database.tblMap[col.fk[1]]
		assert(foreignTbl and foreignTbl.colMap[col.fk[2]])
		table.insert(constr, 'FOREIGN KEY('..col[1]..') REFERENCES '..DbPrefix..col.fk[1]..'('..col.fk[2]..')')
	end
	
	return colDef
end

----------------- SQLite Driver -----------------

Database.Drivers.SQLite = {}
Database.Drivers.SQLite.getColDef = Database.Drivers._common.getColDef

function Database.Drivers.SQLite:makeBackup()
	-- remove backup if there is too many
	local maxBackups = touint(g_Config.maxBackups, 0)
	if(maxBackups > 0) then
		local i = maxBackups
		while(fileExists('backups/db'..i..'.sqlite')) do
			fileDelete('backups/db'..i..'.sqlite')
			i = i + 1
		end
	end
	
	-- rename backups so new file can be the first
	local i = 1
	while(fileExists('backups/db'..i..'.sqlite')) do
		i = i + 1
	end
	
	while(fileExists('backups/db'..(i - 1)..'.sqlite')) do
		fileRename('backups/db'..(i - 1)..'.sqlite', 'backups/db'..i..'.sqlite')
		i = i - 1
	end
	
	-- close connection to database
	destroyElement(g_Connection)
	
	-- copy database file
	if(not fileCopy(SQLITE_DB_PATH, 'backups/db1.sqlite')) then
		outputDebugString('Failed to copy file', 2)
	else
		outputServerLog('Database backup created')
	end
	
	-- reconnect
	g_Connection = dbConnect('sqlite', SQLITE_DB_PATH)
end

local function Database_Drivers_SQLite_AutoBackup()
	local now = getRealTime().timestamp
	
	local backupsInt = touint(g_Config.backupInterval, 0) * 3600 * 24
	if(backupsInt > 1000 and now - Settings.backupTimestamp < backupsInt - 1000) then return end
	
	outputDebugString('Auto-backup...', 3)
	Database.Drivers.SQLite:makeBackup()
	
	Settings.backupTimestamp = now
end

function Database.Drivers.SQLite:init()
	--fileCopy('backups/db1.sqlite', SQLITE_DB_PATH)
	g_Connection = dbConnect('sqlite', SQLITE_DB_PATH)
	if(not g_Connection) then
		outputDebugString('Failed to connect to SQLite database!', 1)
		return false
	end
	
	local backupsInt = touint(g_Config.backupInterval, 0) * 3600 * 24
	if(backupsInt > 0) then
		setTimer(Database_Drivers_SQLite_AutoBackup, 5000, 1) -- make backup just after start
		setTimer(Database_Drivers_SQLite_AutoBackup, backupsInt, 0)
	end
	
	CmdRegister('dbbackup', function()
		Database.Drivers.SQLite.makeBackup()
		privMsg(source, 'Backup saved!')
	end, true)
	
	return true
end

function Database.Drivers.SQLite:query(query, ...)
	local qh = dbQuery(g_Connection, query, ...)
	assert(qh)
	local result, numrows, errmsg = dbPoll(qh, -1)
	
	if(result) then
		return result
	end
	
	outputDebugString('SQL query failed: '..errmsg, 2)
	DbgTraceBack()
	return false
end

function Database.Drivers.SQLite:createTable(tbl)
	local cols, constr = {}, {}
	for i, col in ipairs(tbl) do
		if(col[2]) then -- normal column
			if(col.pk) then -- Primary Key
				-- AUTO_INCREMENT is not needed for SQLite (and is called different)
				local colDef = col[1]..' INTEGER PRIMARY KEY'
				table.insert(cols, colDef)
			else
				local colDef = self:getColDef(col, constr)
				table.insert(cols, colDef)
			end
		elseif(col.unique) then -- unique constraint
			table.insert(constr, 'CONSTRAINT '..DbPrefix..col[1]..' UNIQUE('..table.concat(col.unique, ', ')..')')
		end
	end
	
	local query = 'CREATE TABLE IF NOT EXISTS '..tbl..' ('..
		table.concat(cols, ', ')..((#cols > 0 and #constr > 0) and ', ' or '')..table.concat(constr, ', ')..')'
	--outputDebugString(query, 3)
	return self:query(query)
end

function Database.Drivers.SQLite:insertDefault(tbl)
	-- Note: DEFAULT VALUES is sqlite only
	self:query('INSERT INTO '..tbl..' DEFAULT VALUES')
end

function Database.Drivers.SQLite:getLastInsertID()
	local rows = self:query('SELECT last_insert_rowid() AS id')
	return rows[1].id
end

----------------- MySQL Driver -----------------

Database.Drivers.MySQL = {}
Database.Drivers.MySQL.getColDef = Database.Drivers._common.getColDef

function Database.Drivers.MySQL:init()
	if(not g_Config.host or not g_Config.dbname or not g_Config.username or not g_Config.password) then
		outputDebugString('Required setting for MySQL connection has not been found (host, dbname, username, password)', 1)
		return false
	end
	
	local params = 'dbname='..g_Config.dbname..';host='..g_Config.host
	if(g_Config.port) then
		params = params..';port='..g_Config.port
	end
	
	outputServerLog('MySQL support is experimental!', 3)
	g_Connection = dbConnect('mysql', params, g_Config.username, g_Config.password)
	if(not g_Connection) then
		outputDebugString('Failed to connect to MySQL database!', 1)
		outputDebugString('Params: '..params..' '..g_Config.username..' '..('*'):rep(g_Config.password:len()), 3)
		return false
	end
	
	return true
end

function Database.Drivers.MySQL:query(query, ...)
	local qh = dbQuery(g_Connection, query, ...)
	assert(qh)
	local result, numrows, errmsg = dbPoll(qh, -1)
	
	if(result) then
		return result
	end
	
	outputDebugString('SQL query failed: '..errmsg, 2)
	DbgTraceBack()
	return false
end

function Database.Drivers.MySQL:createTable(tbl)
	local cols, constr = {}, {}
	for i, col in ipairs(tbl) do
		if(col[2]) then -- normal column
			if(col.pk) then -- Primary Key
				local colDef = col[1]..' '..col[2]..' NOT NULL AUTO_INCREMENT PRIMARY KEY'
				table.insert(cols, colDef)
			else
				local colDef = self:getColDef(col, constr)
				table.insert(cols, colDef)
			end
		elseif(col.unique) then -- unique constraint
			table.insert(constr, 'CONSTRAINT '..DbPrefix..col[1]..' UNIQUE('..table.concat(col.unique, ', ')..')')
		end
	end
	
	local query = 'CREATE TABLE IF NOT EXISTS '..tbl..' ('..
		table.concat(cols, ', ')..((#cols > 0 and #constr > 0) and ', ' or '')..table.concat(constr, ', ')..')'
	--outputDebugString(query, 3)
	return self:query(query)
end

function Database.Drivers.MySQL:insertDefault(tbl)
	self:query('INSERT INTO '..self..' () VALUES ()')
end

function Database.Drivers.MySQL:getLastInsertID()
	local rows = self:query('SELECT LAST_INSERT_ID() AS id')
	return rows[1].id
end

----------------- MTA Internal Driver -----------------

Database.Drivers.Internal = {}

function Database.Drivers.Internal:query(query, ...)
	return executeSQLQuery(query, ...)
end

Database.Drivers.Internal.createTable = Database.Drivers.SQLite.createTable
Database.Drivers.Internal.insertDefault = Database.Drivers.SQLite.insertDefault
Database.Drivers.Internal.getLastInsertID = Database.Drivers.SQLite.getLastInsertID

----------------- End -----------------

local function DbLoadConfig()
	local node = xmlLoadFile('conf/database.xml')
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
		outputDebugString('Failed to load database config', 1)
		return false
	end
	
	g_Driver = false
	if(g_Config.type == 'builtin') then
		g_Driver = Database.Drivers.Internal
	elseif(g_Config.type == 'sqlite') then
		g_Driver = Database.Drivers.SQLite
	elseif(g_Config.type == 'mysql') then
		g_Driver = Database.Drivers.MySQL
	end
	
	if(not g_Driver) then
		outputDebugString('Unknown database type '..tostring(g_Config.type), 1)
		return false
	end
	
	DbPrefix = g_Config.tblprefix or ''
	
	if(g_Driver.init and not g_Driver:init()) then
		return false
	end
	
	for i, tbl in ipairs(Database.tblList) do
		local success = g_Driver:createTable(tbl)
		if(not success) then
			outputDebugString('Failed to create '..tbl.name..' table', 1)
			return false
		else
			--outputDebugString('Created '..tbl.name..' table', 3)
		end
	end
	
	g_Ready = true
	return true
end

function DbIsReady()
	return g_Ready
end

Settings.register
{
	name = 'backupTimestamp',
	type = 'INTEGER',
	default = 0,
}
