Resource = Class('Resource')

local g_Map = {}

addEvent('toxic.onResReady')

function Resource.preInit(resName)
	return g_Map[resName]
end

function Resource.__mt.__index:init(resName)
	local res = getResourceFromName(resName)
	local resRoot = res and getResourceRootElement(res)
	local resState = res and getResourceState and getResourceState(res) or 'running'
	local ready = resRoot and not getElementData(resRoot, 'toxic.notReady') and resState == 'running'
	
	--[[if(ready) then
		outputDebugString('Resource '..getResourceName(res)..' is ready when creating object!', 3)
	end]]
	
	self.resName = resName
	self.res = ready and res
	
	self.readyHandlers = {}
	g_Map[resName] = self
end

function Resource.__mt.__index:call(fnName, ...)
	assert(self.res)
	return call(self.res, fnName, ...)
end

function Resource.__mt.__index:isReady()
	return self.res and true
end

function Resource.__mt.__index:addReadyHandler(fn)
	table.insert(self.readyHandlers, fn)
end

local function onResStart(res)
	-- Ignore resource start if not ready
	if(getElementData(source, 'toxic.notReady')) then
		--outputDebugString('Resource '..getResourceName(res)..' is not ready yet!', 3)
		return
	else
		--outputDebugString('Resource '..getResourceName(res)..' is ready when starting!', 3)
	end
	
	local resName = getResourceName(res)
	local self = g_Map[resName]
	if(not self) then return end
	
	self.res = res
	for i, fn in ipairs(self.readyHandlers) do
		fn(self)
	end
	
	--outputDebugString(#self.readyHandlers..' handlers called.', 3)
end

local function onResStop(res)
	local resName = getResourceName(res)
	local self = g_Map[resName]
	if(not self) then return end
	
	self.res = false
end

local function onResReady(res)
	local resName = getResourceName(res)
	local self = g_Map[resName]
	if(not self) then return end
	
	--outputDebugString('Resource '..getResourceName(res)..' is now ready!', 3)
	
	self.res = res
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
