namespace 'db'

local mainConnection = nil
local mainDatabaseType = nil
local tblPrefix = nil

local function loadConfig()
	local node = xmlLoadFile('conf/database.xml')
	if (not node) then return false end
	
	local config = {}
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local key = xmlNodeGetName(subnode)
		local val = xmlNodeGetValue(subnode)
		if (val and val:len() > 0) then
			config[key] = val
		end
	end
	
	xmlUnloadFile(node)
	return config
end

local function autoBackupFunc()
	Debug.info('Auto-backup...')
	db.makeBackup()
	Settings.backupTimestamp = now
end

local function setupBackup(config)
	local backupsInt = touint(config.backupInterval, 0) * 3600 * 24
	if(backupsInt > 0) then
		setTimer(autoBackupFunc, backupsInt, 0)
		setTimer(function()
			local now = getRealTime().timestamp
			if (now - Settings.backupTimestamp > backupsInt) then
				autoBackupFunc()
			end
		end, 5000, 1) -- make backup just after start if needed
	end
	
	Settings.register
	{
		name = 'backupTimestamp',
		type = 'INTEGER',
		default = 0,
	}
	
	CmdMgr.register{
		name = 'dbbackup',
		desc = "Makes script database backup and saves in resource subdirectory",
		accessRight = AccessRight('dbbackup'),
		func = function(ctx)
			db.makeBackup()
			privMsg(ctx.player, 'Backup saved!')
		end
	}
end

local function initDatabase()
	local config = loadConfig()
	if (not config) then
		Debug.err('Failed to load database config')
		return false
	end
	
	if (config.type == 'builtin') then
		mainConnection = db.InternalConnector()
	elseif (config.type == 'sqlite') then
		mainConnection = db.SQLiteConnector(config)
	elseif (config.type == 'mysql') then
		mainConnection = db.MySQLConnector(config)
	end
	
	if (not mainConnection) then
		Debug.err('Unknown database type '..tostring(config.type))
		return false
	end
	
	mainDatabaseType = config.type
	tblPrefix = config.tblprefix or ''
	
	if (mainConnection.connect and not mainConnection:connect()) then
		return false
	end
	
	for i, tbl in ipairs(db.Table.list) do
		local success = mainConnection:createTable(tbl)
		if(not success) then
			Debug.err('Failed to create '..tbl.name..' table')
			return false
		else
			--Debug.info('Created '..tbl.name..' table')
		end
	end
	
	if (mainConnection.makeBackup) then
		setupBackup(config)
	end
	
	return true
end

function getTblPrefix()
	return tblPrefix
end

function getType()
	return mainDatabaseType
end

function getConnection()
	return mainConnection
end

function query(sql, ...)
	return mainConnection:query(sql, ...)
end

function querySingle(sql, ...)
	return mainConnection:querySingle(sql, ...)
end

function queryCount(tbl, whereCond, ...)
	return mainConnection:queryCount(tbl, whereCond, ...)
end

function insertDefault(tbl)
	return mainConnection:insertDefault(tbl)
end

function queryLastInsertID()
	return mainConnection:queryLastInsertID()
end

function beginTransaction()
	return mainConnection:beginTransaction()
end

function endTransaction()
	return mainConnection:endTransaction()
end

function escape(str)
	return mainConnection:escape(str)
end

function blob(data)
	return mainConnection:blob(data)
end

function createTable(tbl)
	return mainConnection:createTable(tbl)
end

function alterColumn(tbl, colInfo)
	return mainConnection:alterColumns(tbl, {colInfo})
end

function alterColumns(tbl, colInfoTbl)
	return mainConnection:alterColumns(tbl, colInfoTbl)
end

function dropColumns(tbl, colNames)
	return mainConnection:dropColumns(tbl, colNames)
end

function addConstraint(tbl, constr)
	return mainConnection:addConstraints(tbl, {constr})
end

function addConstraints(tbl, constrTbl)
	return mainConnection:addConstraints(tbl, constrTbl)
end

function recreateTable(tbl, tblDef)
	return mainConnection:recreateTable(tbl, tblDef)
end

function makeBackup()
	return mainConnection:makeBackup()
end

function verifyAllTables()
	local status = true
	for i, tbl in ipairs(Table.list) do
		if(not mainConnection:verifySchema(tbl)) then
			status = false
		end
	end
	return status
end

addInitFunc(initDatabase, -200)

#if(TEST) then
	Test.register('database2', function()
		local conn = db.SQLiteConnector{path = 'runtime/test.sqlite'}
		conn:connect()
	
		local testTbl = db.Table{
			name = '_test',
			{'id', 'INT UNSIGNED', pk = true},
			{'name', 'VARCHAR(255)'},
			{'nullable', 'VARCHAR(255)', null = true},
			{'test_idx', index = {'name'}},
		}
		Test.check(conn:createTable(testTbl))
		
		Test.check(conn:query('INSERT INTO '..testTbl..' (name, nullable) VALUES(?, ?)', 'Test row', false):poll())
		local id = conn:queryLastInsertID():poll()
		Test.checkGt(id, 0)
		
		local data2
		local data = conn:query('SELECT * FROM '..testTbl..' WHERE id=?', id):callback(function(rows)
			data2 = rows[1]
		end):poll()[1]
		Test.checkTblEq(data, data2)
		
		local count = conn:queryCount(testTbl, 'id=?', id):poll()
		Test.checkEq(count, 1)
		
		local data = conn:querySingle('SELECT * FROM '..testTbl..' WHERE id=?', id):poll()
		Test.checkTblEq(data, {id = id, name = 'Test row', nullable = false}) -- See bug #8174 - hackfixed in db.query
		
		Test.check(conn:query('UPDATE '..testTbl..' SET nullable=?', nil):poll())
		local data = conn:querySingle('SELECT * FROM '..testTbl..' WHERE id=?', id):poll()
		Test.checkTblEq(data, {id = id, name = 'Test row', nullable = false}) -- See bug #8174 - hackfixed in db.query
		
		Test.check(conn:query('UPDATE '..testTbl..' SET nullable=NULL'):poll())
		local data = conn:querySingle('SELECT * FROM '..testTbl..' WHERE id=?', id):poll()
		Test.checkTblEq(data, {id = id, name = 'Test row', nullable = false})
		
		Test.check(conn:query('DROP TABLE '..testTbl):poll())
		testTbl:destroy()
		
		conn:disconnect()
	end)
#end
