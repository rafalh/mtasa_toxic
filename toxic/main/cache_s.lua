namespace('Cache')

local g_Items = {}

function get(name)
	-- Find item in cache
	local descr = g_Items[name]
	if(descr == nil) then return end
	
	-- Update expiration time
	local now = getRealTime().timestamp
	descr[2] = now + descr[3]
	
	-- Return item value
	return descr[1]
end

function set(name, val, sec)
	-- Calculate expiration time
	local now = getRealTime().timestamp
	if(not sec) then sec = 60 end
	local expires = now + sec
	
	-- Add item to the table
	g_Items[name] = {val, expires, sec}
end

function remove(name)
	--Debug.info('Cache.remove \''..name..'\'')
	
	-- Find item in cache
	local descr = g_Items[name]
	if(descr == nil) then return end
	
	-- Destroy associated element
	if(isElement(descr[1])) then
		destroyElement(descr[1])
	elseif(type(descr[1]) == 'table' and descr[1].destroy) then
		descr[1]:destroy()
	end
	
	-- Remove item from table
	g_Items[name] = nil
end

function removeOutdated()
	-- Find all outdated items
	local now = getRealTime().timestamp
	for name, descr in pairs(g_Items) do
		if(now > descr[2]) then
			-- Item is outdated - remove
			remove(name)
		end
	end
end

local function init()
	-- Every 60 seconds remove outdated items
	setTimer(removeOutdated, 60000, 0)
end

addInitFunc(init)

#if (TEST) then
	Test.register('Cache', function()
		Test.checkEq(Cache.get('itemName'), nil)
		
		Cache.set('itemName', 'itemValue', 10)
		Test.checkEq(Cache.get('itemName'), 'itemValue')
		
		Cache.removeOutdated()
		Test.checkEq(Cache.get('itemName'), 'itemValue')
		
		Cache.remove('itemName')
		Test.checkEq(Cache.get('itemName'), nil)
	end)
#end
