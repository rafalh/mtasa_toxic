-- Defines
#local ALWAYS_WAIT = true

-- Globals
local g_Connection, g_Ready, g_Driver = false, false, false
local g_Config = {}
local SQLITE_DB_PATH = 'conf/db.sqlite'

Database = {}
Database.tblList = {}
Database.tblMap = {}
Database.Drivers = {}

DbPrefix = ''

function Database.escape(str)
	return g_Driver and g_Driver:escape(str)
end

function DbBlob(data)
	local tbl = {}
	for i = 1, data:len() do
		local code = data:byte(i)
		table.insert(tbl, ('%02x'):format(code))
	end
	return 'X\''..table.concat(tbl)..'\''
end

function Database.query(query, ...)
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

function Database.querySync(query, ...)
	if(not g_Driver) then return false end
	local prof = DbgPerf(100)
	local result = g_Driver:query(query, ...)
	prof:cp('SQL query %s', query:sub(1, 96))
	return result
end

function Database.querySingle(query, ...)
	local rows = DbQuery(query, ...)
	return rows and rows[1]
end

function Database.queryCount(tbl, whereCond, ...)
	local rows = DbQuery('SELECT COUNT(*) AS c FROM '..tbl..' WHERE '..whereCond, ...)
	return rows and rows[1] and rows[1].c
end

function Database.createTable(tbl)
	return g_Driver and g_Driver:createTable(tbl)
end

function Database.getLastInsertID()
	return g_Driver and g_Driver:getLastInsertID()
end

function Database.alterColumn(tbl, colInfo)
	return g_Driver and g_Driver:alterColumns(tbl, {colInfo})
end

function Database.alterColumns(tbl, colInfoTbl)
	return g_Driver and g_Driver:alterColumns(tbl, colInfoTbl)
end

function Database.dropColumns(tbl, colNames)
	return g_Driver and g_Driver:dropColumns(tbl, colNames)
end

function Database.addConstraint(tbl, constr)
	return g_Driver and g_Driver:addConstraints(tbl, {constr})
end

function Database.addConstraints(tbl, constrTbl)
	return g_Driver and g_Driver:addConstraints(tbl, constrTbl)
end

function Database.recreateTable(tbl, tblDef)
	return g_Driver and g_Driver:recreateTable(tbl, tblDef)
end

-- Legacy API
function DbStr(...)
	return '\''..Database.escape(...)..'\''
end
DbQuery = Database.query
DbQuerySync = Database.querySync
DbQuerySingle = Database.querySingle
DbCount = Database.queryCount
DbRecreateTable = Database.recreateTable

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

function Database.Table.__mt.__index:hasColumn(colName)
	return self.colMap[colName] and true
end

function Database.Table:create(args)
	assert(args.name)
	
	local self = setmetatable({}, Database.Table.__mt)
	self.name = args.name
	self.colMap = {}
	self:addColumns(args)
	
	table.insert(Database.tblList, self)
	assert(not Database.tblMap[self.name], 'Table '..tostring(args.name)..' already exists')
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

function Database.Drivers._common:getConstraints(colInfo, constrTbl)
	if(colInfo.fk) then
		-- Check it here because when original table is defined foreign table can be not existant
		assert(type(colInfo.fk) == 'table')
		local foreignTbl = Database.tblMap[colInfo.fk[1]]
		assert(foreignTbl and foreignTbl.colMap[colInfo.fk[2]])
		table.insert(constrTbl, 'FOREIGN KEY('..colInfo[1]..') REFERENCES '..DbPrefix..colInfo.fk[1]..'('..colInfo.fk[2]..')')
	end
	
	if(colInfo.unique) then -- unique constraint
		assert(type(colInfo.unique) == 'table')
		table.insert(constrTbl, 'UNIQUE('..table.concat(colInfo.unique, ', ')..')')
	end
end

function Database.Drivers._common:getColDef(col)
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
	
	return colDef
end

function Database.Drivers._common:getTblOptions()
	return ''
end

function Database.Drivers._common:createTable(tbl)
	-- Create table
	local tblDef = self:getTblDef(tbl)
	local tblOpts = self:getTblOptions(tbl)
	local query = 'CREATE TABLE IF NOT EXISTS '..tbl..' ('..tblDef..')'..tblOpts
	--Debug.info(query)
	if(not self:query(query)) then return false end
	
	-- Create not unique indexes
	if(not self:createIndexes(tbl)) then return false end
	
	return true
end

function Database.Drivers._common:createIndexes(tbl)
	for i, col in ipairs(tbl) do
		if(col.index) then
			query = 'CREATE INDEX IF NOT EXISTS '..DbPrefix..col[1]..' ON '..tbl..'('..table.concat(col.index, ', ')..')'
			if(not self:query(query)) then return false end
		end
	end
	
	return true
end

function Database.Drivers._common:splitTblDef(tblDef)
	local ret = {}
	local start, i = 1, 1
	while(true) do
		local j, ch = tblDef:match('()([,%(])', i)
		if(not j) then j = tblDef:len() + 1 end
		if(ch == '(') then
			i = tblDef:match('%b()()', j)
		else
			table.insert(ret, tblDef:sub(start, j - 1))
			if(ch) then
				start = j + 1
				i = start
			else
				break
			end
		end
	end
	return ret
end

function Database.Drivers._common:getFieldsFromTblDef(tblDef)
	local fields = {}
	local temp = self:splitTblDef(tblDef)
	for i, colDef in ipairs(temp) do
		local colName = colDef:match('^%s*([%w_]+)')
		if(colName and colName ~= 'CONSTRAINT' and colName ~= 'PRIMARY' and colName ~= 'UNIQUE' and colName ~= 'CHECK' and colName ~= 'FOREIGN') then
			table.insert(fields, colName)
		end
	end
	return fields
end

function Database.Drivers._common:recreateTable(tbl, tblDef)
	if(not self:query('ALTER TABLE '..tbl..' RENAME TO __'..tbl)) then
		return false
	end
	
	if(not tblDef) then
		tblDef = self:getTblDef(tbl)
	elseif(type(tblDef) == 'table') then
		tblDef = self:getTblDef(tblDef)
	end
	local tblOpts = self:getTblOptions(tbl)
	local query = 'CREATE TABLE '..tbl..' ('..tblDef..')'..tblOpts
	
	if(not self:query(query)) then
		Debug.err('Failed to recreate '..tbl.name..' table')
		self:query('ALTER TABLE __'..tbl..' RENAME TO '..tbl)
		return false
	end
	
	local fields = self:getFieldsFromTblDef(tblDef)
	local fieldsStr = table.concat(fields, ',')
	
	if(not self:query('INSERT INTO '..tbl..' SELECT '..fieldsStr..' FROM __'..tbl)) then
		Debug.err('Failed to copy rows when recreating '..tbl.name)
		self:query('DROP TABLE '..tbl)
		self:query('ALTER TABLE __'..tbl..' RENAME TO '..tbl)
		return false
	end
	
	self:query('DROP TABLE __'..tbl)
	
	return true
end

----------------- SQLite Driver -----------------

Database.Drivers.SQLite = table.copy(Database.Drivers._common)

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
	
	Debug.warn('SQL query ('..query..') failed: '..errmsg)
	Debug.printStackTrace(2)
	return false
end

function Database.Drivers.SQLite:exec(query, ...)
	result = dbExec(g_Connection, query, ...)
	
	if(result) then
		return result
	end
	
	Debug.warn('SQL exec failed: '..query)
	Debug.printStackTrace(2)
	return false
end

function Database.Drivers.SQLite:getColDef(col)
	if(col.pk) then -- Primary Key
		-- AUTO_INCREMENT is not needed for SQLite (and is called different)
		return col[1]..' INTEGER PRIMARY KEY NOT NULL'
	else
		return Database.Drivers._common.getColDef(self, col)
	end
end

function Database.Drivers.SQLite:getTblDef(tbl)
	local cols, constr = {}, {}
	for i, colInfo in ipairs(tbl) do
		if(colInfo[2]) then -- normal column
			-- Note: Foreign keys are supported by getColDef
			local colDef = self:getColDef(colInfo)
			table.insert(cols, colDef)
		end
		
		self:getConstraints(colInfo, constr)
	end
	
	return table.concat(cols, ', ')..((#cols > 0 and #constr > 0) and ', ' or '')..table.concat(constr, ', ')
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

function Database.Drivers.SQLite:verifySchema(tbl)
	local realTblDef = self:getTblDefFromDB(tbl)
	if(not realTblDef) then return false end
	
	local validTblDef = self:getTblDef(tbl)
	if(realTblDef == validTblDef) then return true end
	
	local realTbl = self:splitTblDef(realTblDef)
	for i, v in ipairs(realTbl) do
		realTbl[i] = trimStr(v)
	end
	table.sort(realTbl)
	local validTbl = self:splitTblDef(validTblDef)
	for i, v in ipairs(validTbl) do
		validTbl[i] = trimStr(v)
	end
	table.sort(validTbl)
	
	local missing, additional = {}, {}
	local realIdx, validIdx = 1, 1
	while(realIdx < #realTbl or validIdx < #validTbl) do
		local realCol = realTbl[realIdx]
		local validCol = validTbl[validIdx]
		if(realCol == validCol) then
			realIdx = realIdx + 1
			validIdx = validIdx + 1
		elseif(not validCol or (realCol and realCol < validCol)) then
			table.insert(additional, realCol)
			realIdx = realIdx + 1
		else
			table.insert(missing, validCol)
			validIdx = validIdx + 1
		end
	end
	
	if(#missing == 0 and #additional == 0) then return true end
	
	Debug.info('Table schema is not compatible for '..tbl)
	if(#missing > 0) then
		Debug.info('Missing: '..table.concat(missing, ', '))
	end
	if(#additional > 0) then
		Debug.info('Additional: '..table.concat(additional, ', '))
	end
	return false
end

function Database.Drivers.SQLite:getTblDefFromDB(tbl)
	local tblDef = Cache.get('Database.tblDef.'..tbl)
	if(not tblDef) then
		local rows = self:query('SELECT sql FROM sqlite_master WHERE type=\'table\' AND name=?', tostring(tbl))
		local sql = rows and rows[1] and rows[1].sql
		if(not sql) then Debug.warn('Failed to get definition of '..tostring(tbl)..' from sqlite_master: '..tostring(rows)..' '..tostring(rows[1])) return false end
		
		tblDef = sql:match('CREATE TABLE [%w_]+%s*(%b())')
		if(not tblDef) then Debug.warn('Failed to parse sql definition') return false end
		
		tblDef = tblDef:sub(2, -2)
		Cache.set('Database.tblDef.'..tbl, tblDef, 60)
	end
	
	return tblDef
end

function Database.Drivers.SQLite:alterColumns(tbl, colInfoTbl)
	if(#colInfoTbl == 0) then return true end
	
	local tblDef = self:getTblDefFromDB(tbl)
	if(not tblDef) then Debug.warn('getTblDefFromDB failed') return false end
	
	for i, colInfo in ipairs(colInfoTbl) do
		local matches
		tblDef, matches = tblDef:gsub(colInfo[1]..'%s+[^,]+', self:getColDef(colInfo))
		if(matches ~= 1) then Debug.warn('Cannot find '..colInfo[1]..' in alterColumns') return false end
	end
	
	Cache.remove('Database.tblDef.'..tbl)
	return Database.recreateTable(tbl, tblDef)
end

function Database.Drivers.SQLite:dropColumns(tbl, colNames)
	if(#colNames == 0) then return true end
	
	local tblDef = self:getTblDefFromDB(tbl)
	if(not tblDef) then Debug.warn('getTblDefFromDB failed') return false end
	
	for i, colName in ipairs(colNames) do
		local matches
		tblDef, matches = tblDef:gsub(colName..'%s+[^,]+,?', '')
		if(matches ~= 1) then Debug.warn('Cannot find '..colName..' in dropColumns') return false end
	end
	
	Cache.remove('Database.tblDef.'..tbl)
	return Database.recreateTable(tbl, tblDef)
end

function Database.Drivers.SQLite:addConstraints(tbl, constrInfoTbl)
	local tblDef = self:getTblDefFromDB(tbl)
	if(not tblDef) then return false end
	
	local constrTbl = {}
	for i, constrInfo in ipairs(constrInfoTbl) do
		self:getConstraints(constrInfo, constrTbl)
	end
	
	tblDef = tblDef..', '..table.concat(constrTbl, ', ')
	Cache.remove('Database.tblDef.'..tbl)
	return Database.recreateTable(tbl, tblDef)
end

----------------- MySQL Driver -----------------

Database.Drivers.MySQL = table.copy(Database.Drivers._common)

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
	
	Debug.warn('SQL query ('..query..') failed: '..errmsg)
	Debug.printStackTrace(2)
	return false
end

function Database.Drivers.MySQL:exec(query, ...)
	local result = dbExec(g_Connection, query, ...)
	
	if(result) then
		return result
	end
	
	Debug.warn('SQL exec failed: '..query)
	Debug.printStackTrace(2)
	return false
end

function Database.Drivers.MySQL:getColDef(col)
	if(col.pk) then -- Primary Key
		return col[1]..' '..col[2]..' NOT NULL AUTO_INCREMENT PRIMARY KEY'
	else
		return Database.Drivers._common.getColDef(self, col)
	end
end

function Database.Drivers.MySQL:getTblDef(tbl)
	local cols, constr = {}, {}
	for i, colInfo in ipairs(tbl) do
		if(colInfo[2]) then -- normal column
			-- Note: Foreign keys are supported by getColDef
			local colDef = self:getColDef(colInfo)
			table.insert(cols, colDef)
		end
		
		self:getConstraints(colInfo, constr)
	end
	
	return table.concat(cols, ', ')..((#cols > 0 and #constr > 0) and ', ' or '')..table.concat(constr, ', ')
end

function Database.Drivers.MySQL:getTblOptions(tbl)
	return 'CHARACTER SET utf8'
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

function Database.Drivers.MySQL:verifySchema(tbl)
	Debug.warn('Not implemented!')
	return true
end

function Database.Drivers.MySQL:alterColumns(tbl, colInfoTbl)
	for i, colInfo in ipairs(colInfoTbl) do
		local colDef = self:getColDef(colInfo)
		if(not self:query('ALTER TABLE '..tbl..' MODIFY COLUMN '..colDef)) then
			return false
		end
	end
	return true
end

function Database.Drivers.MySQL:dropColumns(tbl, colNames)
	for i, colName in ipairs(colNames) do
		if(not self:query('ALTER TABLE '..tbl..' DROP COLUMN '..colName)) then
			return false
		end
	end
	return true
end

function Database.Drivers.MySQL:addConstraints(tbl, constrInfoTbl)
	local constrTbl = {}
	for i, constrInfo in ipairs(constrInfoTbl) do
		self:getConstraints(colInfo, constrTbl)
	end
	
	for i, constr in ipairs(constrTbl) do
		if(not self:query('ALTER TABLE '..tbl..' ADD CONSTRAINT '..constr)) then return false end
	end
	return true
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
Database.Drivers.Internal.verifySchema = Database.Drivers.SQLite.verifySchema

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

function Database.verifyTables()
	local status = true
	for i, tbl in ipairs(Database.tblList) do
		if(not g_Driver:verifySchema(tbl)) then
			status = false
		end
	end
	return status
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
