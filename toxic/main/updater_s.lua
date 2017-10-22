namespace('Updater')

local g_List = {}
local g_Queue = {}
local g_TablesToRecreate = {}
local g_MaxVer = 0

function register(updateInfo)
	table.insert(g_List, updateInfo)
	g_MaxVer = math.max(g_MaxVer, updateInfo.ver)
end

function queueTableRecreate(tbl)
	table.insert(g_TablesToRecreate, tbl)
end

function run()
	local ver = Settings.version
	if(ver == 0) then
		-- Version is not set in settings table - this is first run
		Settings.version = g_MaxVer
		g_List = {} -- destroy updates list
		Debug.warn('Database version auto-detection: '..g_MaxVer)
		return true
	end
	
	-- Find needed updates
	for i, upd in ipairs(g_List) do
		if(upd.ver > ver) then
			table.insert(g_Queue, upd)
		end
	end
	g_List = {} -- destroy updates list
	
	if(#g_Queue == 0) then
		-- Nothing to do
		return true
	end
	
	-- Sort updates
	table.sort(g_Queue, function(upd1, upd2) return upd1.ver < upd2.ver end)
	
	-- Check if there are all needed updates (no holes)
	for i, upd in ipairs(g_Queue) do
		local prevVer = i > 1 and g_Queue[i - 1].ver or ver
		if(prevVer ~= upd.ver - 1) then
			Debug.err('Update #'..(upd.ver - 1)..' is missing!')
			return false
		end
	end
	
	-- Make backup before update
	db.makeBackup()
	
	-- End MTA transaction (batch option in dbConnect)
	--DbQuery('COMMIT')

	-- Begin transaction
	DbQuery('BEGIN')
	
	-- Start update
	while(#g_Queue > 0) do
		local upd = table.remove(g_Queue, 1)
		
		local status, err = pcall(upd.func)
		if(err) then
			Debug.err('Database update ('..ver..' -> '..upd.ver..') failed: '..tostring(err))
			DbQuery('ROLLBACK')
			DbQuery('BEGIN')
			return false
		end
		
		-- Update version in settings table
		Settings.version = upd.ver
		
		-- Commit changes
		DbQuery('COMMIT')

		-- Begin MTA transaction (batch option in dbConnect)
		--DbQuery('BEGIN')
		
		-- Update succeeded
		Debug.info('Database update ('..ver..' -> '..upd.ver..') succeeded!')
		ver = upd.ver
	end
	
	-- Recreate tables if requested
	for i, tbl in ipairs(g_TablesToRecreate) do
		Database.recreateTable(tbl)
	end
	
	-- Verify tables after update
	db.verifyAllTables()
	
	return true
end
