Resource = Class('Resource')

local g_Map = {}
setmetatable(g_Map, {__mode = 'v'}) -- weak table

addEvent('toxic.onResReady')

function Resource.preInit(name)
	return g_Map[name]
end

function Resource.__mt.__index:init(name)
	local res = getResourceFromName(name)
	local resRoot = res and getResourceRootElement(res)
	local resState = res and getResourceState and getResourceState(res) or 'running'
	local ready = resRoot and not getElementData(resRoot, 'toxic.notReady') and resState == 'running'
	
	--[[if(ready) then
		outputDebugString('Resource '..getResourceName(res)..' is ready when creating object!', 3)
	end]]
	
	self.name = name
	self.res = res
	self.ready = ready
	
	self.readyHandlers = {}
	g_Map[name] = self
end

function Resource.__mt.__index:call(fnName, ...)
	assert(self.ready)
	return call(self.res, fnName, ...)
end

function Resource.__mt.__index:getName()
	return self.name
end

function Resource.__mt.__index:isReady()
	return self.ready
end

function Resource.__mt.__index:exists()
	return self.res and true
end

function Resource.__mt.__index:getRoot()
	return self.res and getResourceRootElement(self.res)
end

function Resource.__mt.__index:addReadyHandler(fn)
	table.insert(self.readyHandlers, fn)
end

local function onResStart(res)
	-- Find resource object
	local resName = getResourceName(res)
	local self = g_Map[resName]
	if(not self) then return end
	
	self.res = res
	self.ready = not getElementData(source, 'toxic.notReady')
	
	if(self.ready) then
		for i, fn in ipairs(self.readyHandlers) do
			fn(self)
		end
		
		--outputDebugString(#self.readyHandlers..' handlers called.', 3)
	end
end

local function onResStop(res)
	local resName = getResourceName(res)
	local self = g_Map[resName]
	if(not self) then return end
	
	self.ready = false
end

local function onResReady(res)
	local resName = getResourceName(res)
	local self = g_Map[resName]
	if(not self) then return end
	
	--outputDebugString('Resource '..getResourceName(res)..' is now ready!', 3)
	
	self.res = res
	self.ready = true
	
	for i, fn in ipairs(self.readyHandlers) do
		fn(self)
	end
	
	--outputDebugString(#self.readyHandlers..' handlers called.', 3)
end

local isServer = triggerClientEvent
local resStartEvent = isServer and 'onResourceStart' or 'onClientResourceStart'
local resStopEvent = isServer and 'onResourceStop' or 'onClientResourceStop'
addEventHandler(resStartEvent, root, onResStart)
addEventHandler(resStopEvent, root, onResStop)
addEventHandler('toxic.onResReady', root, onResReady)
