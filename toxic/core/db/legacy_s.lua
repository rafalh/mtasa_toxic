Database = {}

function DbStr(...)
	return '\''..db.escape(...)..'\''
end

function DbQuery(...)
	return db.query(...):poll()
end

function DbQuerySync(...)
	return db.query(...):poll()
end

function DbQuerySingle(...)
	return db.querySingle(...):poll()
end

function DbCount(...)
	return db.queryCount(...):poll()
end

function Database.getLastInsertID()
	return db.queryLastInsertID():poll()
end

function DbInit()
	return true
end

DbBlob = db.blob
DbRecreateTable = db.recreateTable
Database.escape = db.escape
Database.query = DbQuery
Database.getDriver = db.getConnection
Database.getType = db.getType
Database.createTable = db.createTable
Database.recreateTable = db.recreateTable
Database.alterColumn = db.alterColumn
Database.alterColumns = db.alterColumns
Database.dropColumns = db.dropColumns
Database.addConstraint = db.addConstraint
Database.addConstraints = db.addConstraints
Database.verifyTables = db.verifyTables
Database.Table = db.Table

addInitFunc(function()
	DbPrefix = db.getTblPrefix()
end, -199)
