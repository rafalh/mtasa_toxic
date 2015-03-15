db.BaseQuery = Class('BaseQuery')

function db.BaseQuery.__mt.__index:init(conn, sql, ...)
	self.conn = conn
	self.sql = sql
	self.args = {...}
end

function db.BaseQuery.__mt.__index:poll()
	self.qh = dbQuery(self.conn, self.sql, unpack(self.args))
	return self:_poll()
end

function db.BaseQuery.__mt.__index:_poll()
	local result, numrows, errmsg = dbPoll(self.qh, -1)
	if (not result) then
		Debug.warn('SQL query ('..self.sql..') failed: '..errmsg)
		Debug.printStackTrace(2)
	elseif (self.fmt) then
		result = self.fmt(result)
	end
	
	if (self.cb) then
		self.cb(result)
	end
	
	return result
end

function db.BaseQuery.__mt.__index:callback(cb)
	self.cb = cb
	return self
end

function db.BaseQuery.__mt.__index:formatter(fmt)
	self.fmt = fmt
	return self
end

function db.BaseQuery.__mt.__index:start()
	if (self.cb) then
		self.qh = dbQuery(function()
			self:_poll()
		end, self.conn, self.sql, unpack(self.args))
	else
		dbExec(self.conn, self.sql, unpack(self.args))
	end
end

----------------- Base Connector -----------------

db.BaseConnector = Class('BaseConnector')

local function fixNullsInQuery(sql, args)
	local srcIdx, dstIdx = 1, 1
	sql = sql:gsub('%?%??', function(m)
		if(not args[srcIdx]) then
			srcIdx = srcIdx + 1
			return 'NULL'
		else
			args[dstIdx] = args[srcIdx]
			srcIdx = srcIdx + 1
			dstIdx = dstIdx + 1
		end
	end)
	return sql
end

function db.BaseConnector.__mt.__index:query(sql, ...)
	-- See MTA bug #8174 - its resolved but still doesnt work for 'false'
	local args = {...}
	sql = fixNullsInQuery(sql, args)
	
	return db.BaseQuery(self.conn, sql, unpack(args))
end

function db.BaseConnector.__mt.__index:querySingle(sql, ...)
	return self:query(sql, ...):formatter(function(result)
		return result and result[1]
	end)
end

function db.BaseConnector.__mt.__index:queryCount(tbl, whereCond, ...)
	return self:query('SELECT COUNT(*) AS c FROM '..tbl..' WHERE '..whereCond, ...):formatter(function(result)
		return result and result[1].c
	end)
end

function db.BaseConnector.__mt.__index:getConstraints(colInfo, constrTbl)
	if (colInfo.fk) then
		-- Check it here because when original table is defined foreign table can be not existant
		assert(type(colInfo.fk) == 'table')
		local foreignTbl = db.Table.map[colInfo.fk[1]]
		assert(foreignTbl and foreignTbl.colMap[colInfo.fk[2]])
		table.insert(constrTbl, 'FOREIGN KEY('..colInfo[1]..') REFERENCES '..db.getTblPrefix()..colInfo.fk[1]..'('..colInfo.fk[2]..')')
	end
	
	if (colInfo.unique) then -- unique constraint
		assert(type(colInfo.unique) == 'table')
		table.insert(constrTbl, 'UNIQUE('..table.concat(colInfo.unique, ', ')..')')
	end
end

function db.BaseConnector.__mt.__index:getColDef(col)
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

function db.BaseConnector.__mt.__index:getTblOptions()
	return ''
end

function db.BaseConnector.__mt.__index:createTable(tbl)
	-- Create table
	local tblDef = self:getTblDef(tbl)
	local tblOpts = self:getTblOptions(tbl)
	local query = 'CREATE TABLE IF NOT EXISTS '..tbl..' ('..tblDef..')'..tblOpts
	--Debug.info(query)
	if(not self:query(query):poll()) then return false end
	
	-- Create not unique indexes
	if(not self:createIndexes(tbl)) then return false end
	
	return true
end

function db.BaseConnector.__mt.__index:createIndexes(tbl)
	for i, col in ipairs(tbl) do
		if(col.index) then
			query = 'CREATE INDEX IF NOT EXISTS '..db.getTblPrefix()..col[1]..' ON '..tbl..'('..table.concat(col.index, ', ')..')'
			if (not self:query(query):poll()) then return false end
		end
	end
	
	return true
end

function db.BaseConnector.__mt.__index:splitTblDef(tblDef)
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

function db.BaseConnector.__mt.__index:getFieldsFromTblDef(tblDef)
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

function db.BaseConnector.__mt.__index:recreateTable(tbl, tblDef)
	if(not self:query('ALTER TABLE '..tbl..' RENAME TO __'..tbl):poll()) then
		return false
	end
	
	if(not tblDef) then
		tblDef = self:getTblDef(tbl)
	elseif(type(tblDef) == 'table') then
		tblDef = self:getTblDef(tblDef)
	end
	local tblOpts = self:getTblOptions(tbl)
	local query = 'CREATE TABLE '..tbl..' ('..tblDef..')'..tblOpts
	
	if(not self:query(query):poll()) then
		Debug.err('Failed to recreate '..tbl.name..' table')
		self:query('ALTER TABLE __'..tbl..' RENAME TO '..tbl):poll()
		return false
	end
	
	local fields = self:getFieldsFromTblDef(tblDef)
	local fieldsStr = table.concat(fields, ',')
	
	if(not self:query('INSERT INTO '..tbl..' SELECT '..fieldsStr..' FROM __'..tbl):poll()) then
		Debug.err('Failed to copy rows when recreating '..tbl.name)
		self:query('DROP TABLE '..tbl):poll()
		self:query('ALTER TABLE __'..tbl..' RENAME TO '..tbl):poll()
		return false
	end
	
	self:query('DROP TABLE __'..tbl):poll()
	
	return true
end

function db.BaseConnector.__mt.__index:escape(str)
	return tostring(str):gsub('\'', '\'\'')
end

function db.BaseConnector.__mt.__index:blob(data)
	local tbl = {}
	for i = 1, data:len() do
		local code = data:byte(i)
		table.insert(tbl, ('%02x'):format(code))
	end
	return 'X\''..table.concat(tbl)..'\''
end

----------------- SQLite Connector -----------------

db.SQLiteConnector = Class('SQLiteConnector', db.BaseConnector)

function db.SQLiteConnector.__mt.__index:init(config)
	self.path = config.path or 'runtime/db.sqlite'
end

function db.SQLiteConnector.__mt.__index:connect()
	self.conn = dbConnect('sqlite', self.path)
	if (not self.conn) then
		Debug.err('Failed to connect to SQLite database!')
		return false
	end
	return true
end

function db.SQLiteConnector:disconnect()
	if (not self.conn) then return false end
	destroyElement(self.conn)
	self.conn = false
	return true
end

function db.SQLiteConnector.__mt.__index:getColDef(col)
	if(col.pk) then -- Primary Key
		-- AUTO_INCREMENT is not needed for SQLite (and is called different)
		return col[1]..' INTEGER PRIMARY KEY NOT NULL'
	else
		return self._superClass.__mt.__index.getColDef(self, col)
	end
end

function db.SQLiteConnector.__mt.__index:getTblDef(tbl)
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

function db.SQLiteConnector.__mt.__index:insertDefault(tbl)
	-- Note: DEFAULT VALUES is sqlite only
	self:query('INSERT INTO '..tbl..' DEFAULT VALUES')
end

function db.SQLiteConnector.__mt.__index:queryLastInsertID()
	return self:query('SELECT last_insert_rowid() AS id'):formatter(function(result)
		return result[1].id
	end)
end

function db.SQLiteConnector.__mt.__index:optimize()
	self:query('COMMIT'):poll()
	self:query('VACUUM'):poll()
end

function db.SQLiteConnector.__mt.__index:verifySchema(tbl)
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

function db.SQLiteConnector.__mt.__index:getTblDefFromDB(tbl)
	local tblDef = Cache.get('Database.tblDef.'..tbl)
	if(not tblDef) then
		local rows = self:query('SELECT sql FROM sqlite_master WHERE type=\'table\' AND name=?', tostring(tbl)):poll()
		local sql = rows and rows[1] and rows[1].sql
		if(not sql) then Debug.warn('Failed to get definition of '..tostring(tbl)..' from sqlite_master: '..tostring(rows)..' '..tostring(rows[1])) return false end
		
		tblDef = sql:match('CREATE TABLE [%w_]+%s*(%b())')
		if(not tblDef) then Debug.warn('Failed to parse sql definition') return false end
		
		tblDef = tblDef:sub(2, -2)
		Cache.set('Database.tblDef.'..tbl, tblDef, 60)
	end
	
	return tblDef
end

function db.SQLiteConnector.__mt.__index:alterColumns(tbl, colInfoTbl)
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

function db.SQLiteConnector.__mt.__index:dropColumns(tbl, colNames)
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

function db.SQLiteConnector.__mt.__index:addConstraints(tbl, constrInfoTbl)
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

function db.SQLiteConnector.__mt.__index:makeBackup()
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
	while (fileExists('backups/db'..i..'.sqlite')) do
		i = i + 1
	end
	
	while (fileExists('backups/db'..(i - 1)..'.sqlite')) do
		fileRename('backups/db'..(i - 1)..'.sqlite', 'backups/db'..i..'.sqlite')
		i = i - 1
	end
	
	-- close connection to database
	self:disconnect()
	
	-- copy database file
	if (not fileCopy(self.path, 'backups/db1.sqlite')) then
		Debug.warn('Failed to copy file')
	else
		outputServerLog('Database backup created')
	end
	
	-- reconnect
	self:connect()
end

----------------- MySQL Driver -----------------

db.MySQLConnector = Class('MySQLConnector', db.BaseConnector)

function db.MySQLConnector.__mt.__index:init(config)
	self.host = config.host
	self.dbname = config.dbname
	self.user = config.username
	self.password = config.password
end

function db.MySQLConnector.__mt.__index:connect()
	if(not self.host or not self.dbname or not self.username or not self.password) then
		Debug.err('Required setting for MySQL connection has not been found (host, dbname, username, password)', 1)
		return false
	end
	
	local params = 'dbname='..g_Config.dbname..';host='..g_Config.host
	if(g_Config.port) then
		params = params..';port='..g_Config.port
	end
	
	Debug.warn('MySQL support is experimental!')
	self.conn = dbConnect('mysql', params, g_Config.username, g_Config.password)
	if(not self.conn) then
		Debug.err('Failed to connect to MySQL database - '..params..' '..g_Config.username..' '..('*'):rep(g_Config.password:len()))
		return false
	end
	
	return true
end

function db.MySQLConnector.__mt.__index:disconnect()
	if(not self.conn) then return false end
	destroyElement(self.conn)
	self.conn = false
	return true
end

function db.MySQLConnector.__mt.__index:escape(str)
	return tostring(str):gsub('\\', '\\\\'):gsub('\'', '\\\'')
end

function db.MySQLConnector.__mt.__index:getColDef(col)
	if (col.pk) then -- Primary Key
		return col[1]..' '..col[2]..' NOT NULL AUTO_INCREMENT PRIMARY KEY'
	else
		return self._superClass.__mt.__index.getColDef(self, col)
	end
end

function db.MySQLConnector.__mt.__index:getTblDef(tbl)
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

function db.MySQLConnector.__mt.__index:getTblOptions(tbl)
	return 'CHARACTER SET utf8'
end


function db.MySQLConnector.__mt.__index:insertDefault(tbl)
	self:query('INSERT INTO '..self..' () VALUES ()'):poll()
end

function db.MySQLConnector.__mt.__index:queryLastInsertID()
	return self:query('SELECT LAST_INSERT_ID() AS id'):formatter(function(result)
		return rows[1].id
	end)
end

function db.MySQLConnector.__mt.__index:optimize()
	local tableNames = {}
	for i, tbl in ipairs(Database.tblList) do
		table.insert(tableNames, tbl.name)
	end
	self:query('OPTIMIZE TABLE '..table.concat(tableNames, ', ')):poll()
end

function db.MySQLConnector.__mt.__index:verifySchema(tbl)
	Debug.warn('Not implemented!')
	return true
end

function db.MySQLConnector.__mt.__index:alterColumns(tbl, colInfoTbl)
	for i, colInfo in ipairs(colInfoTbl) do
		local colDef = self:getColDef(colInfo)
		if (not self:query('ALTER TABLE '..tbl..' MODIFY COLUMN '..colDef):poll()) then
			return false
		end
	end
	return true
end

function db.MySQLConnector.__mt.__index:dropColumns(tbl, colNames)
	for i, colName in ipairs(colNames) do
		if (not self:query('ALTER TABLE '..tbl..' DROP COLUMN '..colName):poll()) then
			return false
		end
	end
	return true
end

function db.MySQLConnector.__mt.__index:addConstraints(tbl, constrInfoTbl)
	local constrTbl = {}
	for i, constrInfo in ipairs(constrInfoTbl) do
		self:getConstraints(colInfo, constrTbl)
	end
	
	for i, constr in ipairs(constrTbl) do
		if (not self:query('ALTER TABLE '..tbl..' ADD CONSTRAINT '..constr):poll()) then return false end
	end
	return true
end

----------------- MTA Internal Registry Connector -----------------
db.InternalQuery = Class('InternalQuery', db.BaseQuery)

function db.InternalQuery.__mt.__index:init(sql, ...)
	self.sql = sql
	self.args = {...}
end

function db.InternalQuery.__mt.__index:poll()
	local result = executeSQLQuery(self.sql, unpack(self.args))
	if (not result) then
		Debug.warn('SQL query ('..self.sql..') failed')
		Debug.printStackTrace(2)
	elseif (self.fmt) then
		result = self.fmt(result)
	end
	
	if (self.cb) then
		self.cb(result)
	end
	
	return result
end

db.InternalQuery.__mt.__index.start = db.InternalQuery.__mt.__index.poll

db.InternalConnector = Class('InternalConnector', db.SQLiteConnector)

function db.InternalConnector.__mt.__index:init()
end

function db.InternalConnector.__mt.__index:connect()
	return true
end

function db.InternalConnector:disconnect()
	return false
end

function db.InternalConnector.__mt.__index:query(sql, ...)
	-- See MTA bug #8174 - its resolved but still doesnt work for 'false'
	local args = {...}
	sql = fixNullsInQuery(sql, args)
	
	return db.InternalQuery(sql, unpack(args))
end
