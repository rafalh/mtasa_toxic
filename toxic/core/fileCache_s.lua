namespace('FileCache')

CacheTable = Database.Table{
	name = 'cache',
	{'id', 'INT UNSIGNED', pk = true},
	{'name', 'VARCHAR(255)'},
	{'filename', 'VARCHAR(255)'},
	{'duration', 'INT UNSIGNED'},
	{'expires', 'INT UNSIGNED'},
	{'cache_idx', unique = {'name'}},
}

local CACHE_DIR = 'runtime/cache/'

function get(name)
	-- Find item in cache
	local data = DbQuerySingle('SELECT * FROM '..CacheTable..' WHERE name=?', name)
	if (not data) then return nil end
	
	-- Update expiration time
	local now = getRealTime().timestamp
	DbQuery('UPDATE '..CacheTable..' SET expires=? WHERE id=?', now + data.duration, data.id)
	
	-- Return item value
	return fileGetContents(CACHE_DIR..data.filename)
end

function set(name, val, sec)
	-- Calculate expiration time
	local now = getRealTime().timestamp
	if (not sec) then sec = 60 end
	local expires = now + sec
	
	-- Add item to the table
	local data = DbQuerySingle('SELECT id, filename FROM '..CacheTable..' WHERE name=?', name)
	local filename = data and data.filename or md5(name)
	
	if (fileSetContents(CACHE_DIR..filename, val)) then
		if (data) then
			DbQuery('UPDATE '..CacheTable..' SET duration=?, expires=? WHERE id=?', sec, expires, data.id)
		else
			DbQuery('INSERT INTO '..CacheTable..' (name, filename, duration, expires) VALUES(?, ?, ?, ?)', name, filename, sec, expires)
		end
	elseif (data) then
		-- Failed to save new value - remove old
		if (fileExists(CACHE_DIR..filename)) then
			fileDelete(CACHE_DIR..filename)
		end
		DbQuery('DELETE FROM '..CacheTable..' WHERE id=?', data.id)
	end
end

function remove(name)
	--Debug.info('FileCache.remove \''..name..'\'')
	
	-- Delete item from cache
	local data = DbQuerySingle('SELECT id, filename FROM '..CacheTable..' WHERE name=?', name)
	if (not data) then return end
	
	fileDelete(CACHE_DIR..data.filename)
	DbQuery('DELETE FROM '..CacheTable..' WHERE id=?', data.id)
end

function removeOutdated()
	-- Find all outdated items
	local now = getRealTime().timestamp
	local idList = {}
	local rows = DbQuery('SELECT * FROM '..CacheTable..' WHERE expires<?', now)
	for i, data in ipairs(rows) do
		fileDelete(CACHE_DIR..data.filename)
		table.insert(idList, data.id)
	end
	
	local idListStr = table.concat(idList, ',')
	DbQuery('DELETE FROM '..CacheTable..' WHERE id IN ('..idListStr..')')
end

local function init()
	-- Every 60 seconds remove outdated items
	setTimer(removeOutdated, 60*1000, 0)
end

addInitFunc(init)

#if (TEST) then
	Test.register('FileCache', function()
		Test.checkEq(FileCache.get('itemName'), nil)
		
		FileCache.set('itemName', 'itemValue', 10)
		Test.checkEq(FileCache.get('itemName'), 'itemValue')
		
		FileCache.removeOutdated()
		Test.checkEq(FileCache.get('itemName'), 'itemValue')
		
		FileCache.remove('itemName')
		Test.checkEq(FileCache.get('itemName'), nil)
	end)
#end
