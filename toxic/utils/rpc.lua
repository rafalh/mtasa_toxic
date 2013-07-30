--[[ Syntax propositions:
  RPC.create('getPlayerStats', 1):onResult(onPlStats):exec()
* RPC('getPlayerStats', 1):onResult(onPlStats):exec()
  callServer{'getPlayerStats', 1, onResult = onPlStats}
]]

local RpcMethods = {}
local g_WaitingRpc = {}
local g_AllowedRpc = {}
local SERVER = triggerClientEvent and true

addEvent('main.onRpc', true)
addEvent('main.onRpcResult', true)

function RpcMethods.onResult(self, fn)
	self.callback = fn
	return self
end

function RpcMethods.exec(self)
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

function RpcMethods.setCallbackArgs(self, ...)
	self.cbArgs = {...}
	return self
end

if(SERVER) then
	function RpcMethods.setClient(self, cl)
		self.client = cl
		return self
	end
	
	function allowRPC(fnName)
		g_AllowedRpc[fnName] = true
	end
end

function RPC(fnName, ...)
	local mt = {__index = RpcMethods}
	local self = setmetatable({}, mt)
	self.fn = fnName
	self.args = {...}
	self.cbArgs = {}
	self.id = false
	if(SERVER) then
		self.client = root
	end
	return self
end

local function onRpc(id, fnName, ...)
	if(SERVER and not g_AllowedRpc[fnName]) then
		outputDebugString('Denied RPC: '..tostring(fnName), 2)
		return
	end
	
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
end

local function onRpcResult(id, ...)
	local self = g_WaitingRpc[id]
	if(not self) then
		outputDebugString('Unknown RPC '..tostring(id), 2)
		return
	end
	g_WaitingRpc[id] = nil
	for i, arg in ipairs({...}) do
		table.insert(self.cbArgs, arg)
	end
	self.callback(unpack(self.cbArgs))
end

addEventHandler('main.onRpc', resourceRoot, onRpc)
addEventHandler('main.onRpcResult', resourceRoot, onRpcResult)
