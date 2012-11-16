-----------------
-- Definitions --
-----------------

#DB_HOST = ""
#DB_USER = ""
#DB_PASSWORD = ""
#DB_DATABASE = ""

---------------------
-- Local variables --
---------------------

local g_Connection = nil

--------------------------------
-- Local function definitions --
--------------------------------

local function onResourceStart ()
	g_Connection = dbConnect ( "mysql", $(DB_HOST), $(DB_USER), $(DB_PASSWORD) )
	if ( not g_Connection ) then
		cancelEvent ()
		outputDebugString ( "Cannot connect to MySQL database.", 1 )
		return
	end
	
	local qh = dbQuery ( g_Connection, "USE "..$(DB_DATABASE) )
	local result = dbPoll ( qh, -1 )
	if ( not result ) then
		cancelEvent ()
		outputDebugString ( "Cannot select MySQL database.", 1 )
		return
	end
	
	addEventHandler ( "onResourceStop", g_ResRoot, onResourceStop )
end

local function onResourceStop ()
	destroyElement ( g_Connection )
end

---------------------------------
-- Global function definitions --
---------------------------------

function executeSQLCreateTable ( tableName, definition )
	local qh = dbQuery ( g_Connection, "CREATE TABLE IF NOT EXISTS "..tableName.." ( "..definition.." )" )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		dbFree ( result ) -- Freeing the result is IMPORTANT
		return true
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

function executeSQLDelete ( tableName, conditions )
	local qh = dbQuery ( g_Connection, "DELETE FROM "..tableName.." WHERE "..conditions )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		dbFree ( result ) -- Freeing the result is IMPORTANT
		return true
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

function executeSQLDropTable ( tableName )
	local qh = dbQuery ( g_Connection, "DROP TABLE "..tableName )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		dbFree ( result ) -- Freeing the result is IMPORTANT
		return true
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

function executeSQLInsert ( tableName, values, columns )
	local qh = dbQuery ( g_Connection, "INSERT INTO "..tableName..( " "..columns or "" ).." VALUES "..values )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		dbFree ( result ) -- Freeing the result is IMPORTANT
		return true
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

function executeSQLQuery ( query, ... )
	local qh = dbQuery ( g_Connection, query, ... )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		return result
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

function executeSQLSelect ( tableName, fields, conditions, limit )
	local qh = dbQuery ( g_Connection, "SELECT "..fields.." FROM "..tableName..( ( conditions and " WHERE "..conditions ) or "" )..( ( limit and " LIMIT "..limit ) or "") )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		return result
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

function executeSQLUpdate ( tableName, set, conditions )
	local query = "UPDATE "..tableName.." SET "..set
	if ( conditions ) then
		query = query.." WHERE "..conditions
	end
	local qh = dbQuery ( g_Connection, query )
	local result, numrows, errmsg = dbPoll ( qh, -1 )
	
	if ( result ) then
		dbFree ( result ) -- Freeing the result is IMPORTANT
		return true
	end
	
	outputDebugString ( "SQL query failed: "..errmsg, 2 )
	return false
end

------------
-- Events --
------------

addEventHandler ( "onResourceStart", g_ResRoot, onResourceStart )
