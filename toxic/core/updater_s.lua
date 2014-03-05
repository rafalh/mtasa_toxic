namespace('Updater')

local g_List = {}
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
		Debug.warn('Database version auto-detection: '..g_MaxVer)
		return true
	end
	
	-- Find needed updates
	local queue = {}
	for i, upd in ipairs(g_List) do
		if(upd.ver > ver) then
			table.insert(queue, upd)
		end
	end
	
	if(#queue == 0) then
		-- Nothing to do
		return true
	end
	
	-- Sort updates
	table.sort(queue, function(upd1, upd2) return upd1.ver < upd2.ver end)
	
	-- Check if there are all needed updates (no holes)
	for i, upd in ipairs(queue) do
		local prevVer = i > 1 and queue[i - 1].ver or ver
		if(prevVer ~= upd.ver - 1) then
			Debug.err('Update #'..(upd.ver - 1)..' is missing!')
			return false
		end
	end
	
	-- Make backup before update
	Database.makeBackup()
	
	-- Begin transaction
	DbQuery('COMMIT')
	DbQuery('BEGIN')
	
	-- Start update
	for i, upd in ipairs(queue) do
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
		DbQuery('BEGIN')
		
		-- Update succeeded
		Debug.info('Database update ('..ver..' -> '..upd.ver..') succeeded!')
		ver = upd.ver
	end
	
	-- Recreate tables if requested
	for i, tbl in ipairs(g_TablesToRecreate) do
		Database.recreateTable(tbl)
	end
	
	-- Verify tables after update
	Database.verifyTables()
	
	return true
end
