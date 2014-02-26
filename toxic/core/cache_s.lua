namespace('Cache')

local g_Items = {}

function get(name)
	-- Get item from cache table
	return g_Items[name][1]
end

function set(name, val, sec)
	-- Calculate time limit
	local now = getRealTime().timestamp
	local limit = now + (sec or 60)
	
	-- Add item to the table
	g_Items[name] = {val, limit}
end

function remove(name)
	-- Find item in cache
	local descr = g_Items[name]
	if(not descr) then return end
	
	-- Destroy associated element
	if(isElement(descr[1])) then
		destroyElement(descr[1])
	elseif(descr[1].destroy) then
		descr[1]:destroy()
	end
	
	-- Remove item from table
	g_Items[name] = nil
end

local function removeOutdated()
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
