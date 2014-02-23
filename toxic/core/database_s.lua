-- Defines
#local ALWAYS_WAIT = false

-- Globals
local g_Connection, g_Ready, g_Driver = false, false, false
local g_Config = {}
local SQLITE_DB_PATH = 'conf/db.sqlite'

Database = {}
Database.tblList = {}
Database.tblMap = {}
Database.Drivers = {}

DbPrefix = ''

function DbStr(str)
	return '\''..g_Driver:escape(str)..'\''
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
		Debug.err('Failed to recreate '..tbl.name..' table')
		DbQuery('ALTER TABLE __'..tbl..' RENAME TO '..tbl)
		return false
	end
	
	if(not DbQuery('INSERT INTO '..tbl..' SELECT '..fieldsStr..' FROM __'..tbl)) then
		Debug.err('Failed to copy rows when recreating '..tbl.name)
		DbQuery('DROP TABLE '..tbl)
		DbQuery('ALTER TABLE __'..tbl..' RENAME TO '..tbl)
		return false
	end
	
	DbQuery('DROP TABLE __'..tbl)
	
	return true
end

function DbQuery(query, ...)
	if(not g_Driver) then return false end
	local prof = DbgPerf(100)
	local result
	if(query:sub(1, 6):upper() == 'SELECT' or $ALWAYS_WAIT) then
		result = g_Driver:query(query, ...)
	else
		result = g_Driver:exec(query, ...)
	end
	prof:cp('SQL query %s', query:sub(1, 96))
	return result
end

function DbQuerySync(query, ...)
	if(not g_Driver) then return false end
	local prof = DbgPerf(100)
	local result = g_Driver:query(query, ...)
	prof:cp('SQL query %s', query:sub(1, 96))
	return result
end

function DbQuerySingle(query, ...)
	local rows = DbQuery(query, ...)
	return rows and rows[1]
end

function DbCount(tbl, whereCond, ...)
	local rows = DbQuery('SELECT COUNT(*) AS c FROM '..tbl..' WHERE '..whereCond, ...)
	return rows and rows[1] and rows[1].c
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
		Debug.warn('Failed to copy file')
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
	
	Debug.info('Auto-backup...')
	Database.Drivers.SQLite:makeBackup()
	
	Settings.backupTimestamp = now
end

function Database.Drivers.SQLite:init()
	--fileCopy('backups/db1.sqlite', SQLITE_DB_PATH)
	g_Connection = dbConnect('sqlite', SQLITE_DB_PATH)
	if(not g_Connection) then
		Debug.err('Failed to connect to SQLite database!')
		return false
	end
	
	local backupsInt = touint(g_Config.backupInterval, 0) * 3600 * 24
	if(backupsInt > 0) then
		setTimer(Database_Drivers_SQLite_AutoBackup, 5000, 1) -- make backup just after start
		setTimer(Database_Drivers_SQLite_AutoBackup, backupsInt, 0)
	end
	
	CmdMgr.register{
		name = 'dbbackup',
		desc = "Makes script database backup and saves in resource subdirectory",
		accessRight = AccessRight('dbbackup'),
		func = function(ctx)
			Database.Drivers.SQLite.makeBackup()
			privMsg(ctx.player, 'Backup saved!')
		end
	}
	
	return true
end

function Database.Drivers.SQLite:escape(str)
	return tostring(str):gsub('\'', '\'\'')
end

function Database.Drivers.SQLite:query(query, ...)
	local qh = dbQuery(g_Connection, query, ...)
	assert(qh)
	local result, numrows, errmsg = dbPoll(qh, -1)
	
	if(result) then
		return result
	end
	
	Debug.warn('SQL query ('..query:sub(1, 100)..') failed: '..errmsg)
	DbgTraceBack()
	return false
end

function Database.Drivers.SQLite:exec(query, ...)
	result = dbExec(g_Connection, query, ...)
	
	if(result) then
		return result
	end
	
	Debug.warn('SQL exec failed: '..query)
	DbgTraceBack()
	return false
end

function Database.Drivers.SQLite:createTable(tbl)
	local cols, constr, indexes = {}, {}, {}
	for i, col in ipairs(tbl) do
		if(col[2]) then -- normal column
			local colDef
			if(col.pk) then -- Primary Key
				-- AUTO_INCREMENT is not needed for SQLite (and is called different)
				colDef = col[1]..' INTEGER PRIMARY KEY NOT NULL'
			else
				colDef = self:getColDef(col, constr)
			end
			table.insert(cols, colDef)
			
			if(col.fk) then
				table.insert(constr, 'FOREIGN KEY('..col[1]..') REFERENCES '..DbPrefix..col.fk[1]..'('..col.fk[2]..')')
			end
		elseif(col.unique) then -- unique constraint
			table.insert(constr, 'CONSTRAINT '..DbPrefix..col[1]..' UNIQUE('..table.concat(col.unique, ', ')..')')
		elseif(col.index) then -- index descriptor
			table.insert(indexes, col)
		end
	end
	
	local query = 'CREATE TABLE IF NOT EXISTS '..tbl..' ('..
		table.concat(cols, ', ')..((#cols > 0 and #constr > 0) and ', ' or '')..table.concat(constr, ', ')..')'
	--Debug.info(query, 3)
	if(not self:query(query)) then return false end
	
	for i, col in ipairs(indexes) do
		query = 'CREATE INDEX IF NOT EXISTS '..DbPrefix..col[1]..' ON '..tbl..'('..table.concat(col.index, ', ')..')'
		if(not self:query(query)) then return false end
	end
	
	return true
end

function Database.Drivers.SQLite:insertDefault(tbl)
	-- Note: DEFAULT VALUES is sqlite only
	self:query('INSERT INTO '..tbl..' DEFAULT VALUES')
end

function Database.Drivers.SQLite:getLastInsertID()
	local rows = self:query('SELECT last_insert_rowid() AS id')
	return rows[1].id
end

function Database.Drivers.SQLite:optimize()
	self:query('COMMIT')
	self:query('VACUUM')
end

----------------- MySQL Driver -----------------

Database.Drivers.MySQL = {}
Database.Drivers.MySQL.getColDef = Database.Drivers._common.getColDef

function Database.Drivers.MySQL:init()
	if(not g_Config.host or not g_Config.dbname or not g_Config.username or not g_Config.password) then
		Debug.err('Required setting for MySQL connection has not been found (host, dbname, username, password)', 1)
		return false
	end
	
	local params = 'dbname='..g_Config.dbname..';host='..g_Config.host
	if(g_Config.port) then
		params = params..';port='..g_Config.port
	end
	
	outputServerLog('MySQL support is experimental!', 3)
	g_Connection = dbConnect('mysql', params, g_Config.username, g_Config.password)
	if(not g_Connection) then
		Debug.err('Failed to connect to MySQL database!')
		Debug.info('Params: '..params..' '..g_Config.username..' '..('*'):rep(g_Config.password:len()))
		return false
	end
	
	return true
end

function Database.Drivers.MySQL:escape(str)
	return tostring(str):gsub('\\', '\\\\'):gsub('\'', '\\\'')
end

function Database.Drivers.MySQL:query(query, ...)
	local qh = dbQuery(g_Connection, query, ...)
	assert(qh)
	local result, numrows, errmsg = dbPoll(qh, -1)
	
	if(result) then
		return result
	end
	
	Debug.warn('SQL query ('..query:sub(1, 100)..') failed: '..errmsg)
	DbgTraceBack()
	return false
end

function Database.Drivers.MySQL:exec(query, ...)
	local result = dbExec(g_Connection, query, ...)
	
	if(result) then
		return result
	end
	
	Debug.warn('SQL exec failed: '..query)
	DbgTraceBack()
	return false
end

function Database.Drivers.MySQL:createTable(tbl)
	local cols, constr, indexes = {}, {}, {}
	for i, col in ipairs(tbl) do
		if(col[2]) then -- normal column
			local colDef
			if(col.pk) then -- Primary Key
				colDef = col[1]..' '..col[2]..' NOT NULL AUTO_INCREMENT PRIMARY KEY'
			else
				colDef = self:getColDef(col, constr)
			end
			table.insert(cols, colDef)
			
			if(col.fk) then
				table.insert(constr, 'FOREIGN KEY('..col[1]..') REFERENCES '..DbPrefix..col.fk[1]..'('..col.fk[2]..')')
			end
		elseif(col.unique) then -- unique constraint
			table.insert(constr, 'CONSTRAINT '..DbPrefix..col[1]..' UNIQUE('..table.concat(col.unique, ', ')..')')
		end
	end
	
	local query = 'CREATE TABLE IF NOT EXISTS '..tbl..' ('..
		table.concat(cols, ', ')..((#cols > 0 and #constr > 0) and ', ' or '')..table.concat(constr, ', ')..')'
	--Debug.info(query)
	if(not self:query(query)) then return false end
	
	for i, col in ipairs(indexes) do
		query = 'CREATE INDEX IF NOT EXISTS '..DbPrefix..col[1]..' ON '..tbl..'('..table.concat(col.index, ', ')..')'
		if(not self:query(query)) then return false end
	end
	
	return true
end

function Database.Drivers.MySQL:insertDefault(tbl)
	self:query('INSERT INTO '..self..' () VALUES ()')
end

function Database.Drivers.MySQL:getLastInsertID()
	local rows = self:query('SELECT LAST_INSERT_ID() AS id')
	return rows[1].id
end

function Database.Drivers.MySQL:optimize()
	local tableNames = {}
	for i, tbl in ipairs(Database.tblList) do
		table.insert(tableNames, tbl.name)
	end
	self:query('OPTIMIZE TABLE '..table.concat(tableNames, ', '))
end

----------------- MTA Internal Driver -----------------

Database.Drivers.Internal = {}

function Database.Drivers.Internal:query(query, ...)
	return executeSQLQuery(query, ...)
end

Database.Drivers.Internal.exec = Database.Drivers.Internal.query
Database.Drivers.Internal.escape = Database.Drivers.SQLite.escape
Database.Drivers.Internal.createTable = Database.Drivers.SQLite.createTable
Database.Drivers.Internal.insertDefault = Database.Drivers.SQLite.insertDefault
Database.Drivers.Internal.getLastInsertID = Database.Drivers.SQLite.getLastInsertID
Database.Drivers.Internal.optimize = Database.Drivers.SQLite.optimize

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
		Debug.err('Failed to load database config')
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
		Debug.err('Unknown database type '..tostring(g_Config.type))
		return false
	end
	
	DbPrefix = g_Config.tblprefix or ''
	
	if(g_Driver.init and not g_Driver:init()) then
		return false
	end
	
	for i, tbl in ipairs(Database.tblList) do
		local success = g_Driver:createTable(tbl)
		if(not success) then
			Debug.err('Failed to create '..tbl.name..' table')
			return false
		else
			--Debug.info('Created '..tbl.name..' table')
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
