RPC = Class('RPC')

local g_WaitingRpc = {}
local g_AllowedRpc = {}
local SERVER = triggerClientEvent and true

addEvent('main.onRpc', true)
addEvent('main.onRpcResult', true)

function RPC.__mt.__index:onResult(fn, ...)
	self.callback = fn
	self.cbArgs = {...}
	return self
end

function RPC.__mt.__index:exec()
	if(self.callback) then
		self.id = #g_WaitingRpc + 1
		g_WaitingRpc[self.id] = self
	end
	if(SERVER) then
		return triggerClientEvent(self.client, 'main.onRpc', resourceRoot, self.id, self.fn, unpack(self.args))
	else
		return triggerServerEvent('main.onRpc', resourceRoot, self.id, self.fn, unpack(self.args))
	end
end

if(SERVER) then
	function RPC.__mt.__index:setClient(cl)
		self.client = cl
		return self
	end
	
	function RPC.allow(fnName)
		g_AllowedRpc[fnName] = true
	end
end

function RPC.__mt.__index:init(fnName, ...)
	self.fn = fnName
	self.args = {...}
	self.cbArgs = {}
	self.id = false
	if(SERVER) then
		self.client = root
	end
end

local function onRpc(id, fnName, ...)
	if(SERVER and not g_AllowedRpc[fnName]) then
		outputDebugString('Denied RPC: '..tostring(fnName), 2)
		return
	end
	
	local prof = DbgPerf()
	
	local fn = loadstring('return '..fnName)()
	local results = {}
	if(fn) then
		results = {pcall(fn, ...)}
		if(not results[1]) then
			outputDebugString('RPC failed: '..results[2], 2)
			results = {}
		end
	else
		outputDebugString('Failed to execute RPC '..tostring(fnName), 2)
	end
	if(id) then
		if(SERVER) then
			triggerClientEvent(client, 'main.onRpcResult', resourceRoot, id, unpack(results, 2))
		else
			triggerServerEvent('main.onRpcResult', resourceRoot, id, unpack(results, 2))
		end
	end
	
	prof:cp('RPC '..fnName)
end

local function onRpcResult(id, ...)
	local prof = DbgPerf()
	
	-- Get object reference
	local self = g_WaitingRpc[id]
	if(not self) then
		outputDebugString('Unknown RPC '..tostring(id), 2)
		return
	end
	g_WaitingRpc[id] = nil
	
	-- Call the callback
	for i, arg in ipairs({...}) do
		table.insert(self.cbArgs, arg)
	end
	self.callback(unpack(self.cbArgs))
	
	prof:cp('RPC result')
end

addEventHandler('main.onRpc', resourceRoot, onRpc)
addEventHandler('main.onRpcResult', resourceRoot, onRpcResult)
