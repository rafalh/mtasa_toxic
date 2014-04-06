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
		if(type(self.clients) ~= 'table') then
			assert(isElement(self.clients))
			self.clients = getElementsByType('player', self.clients)
		elseif(self.clients.el) then
			self.clients = {self.clients}
		end
		
		local readyClients = {}
		for i, client in ipairs(self.clients) do
			local pl = type(client) == 'table' and client or Player.fromEl(client)
			if(pl and pl.sync) then
				table.insert(readyClients, pl.el)
			end
		end
		
		return triggerClientEvent(readyClients, 'main.onRpc', resourceRoot, self.id, self.fn, unpack(self.args))
	else
		return triggerServerEvent('main.onRpc', resourceRoot, self.id, self.fn, unpack(self.args))
	end
end

if(SERVER) then
	function RPC.__mt.__index:setClient(clients)
		self.clients = clients
		if(type(clients) ~= 'table' and getElementType(clients) == 'player') then
			local pl = Player.fromEl(clients)
			if(not pl or not pl.sync) then
				Debug.warn('Client is not ready in RPC:setClient')
				Debug.printStackTrace(2, 2, 1)
			end
		end
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
		self.clients = root
	end
end

local function onRpc(id, fnName, ...)
	fnName = tostring(fnName)
	
	if(SERVER and not g_AllowedRpc[fnName]) then
		outputDebugString('Denied RPC: '..fnName, 2)
		return
	end
	
	local prof = DbgPerf()

	local fn = loadstring('return '..fnName)()
	local results = {}
	if(fn) then
		source = client
		results = {pcall(fn, ...)}
		if(not results[1]) then
			outputDebugString('RPC '..fnName..' failed: '..results[2], 2)
			results = {}
		end
	else
		outputDebugString('Failed to execute RPC '..fnName, 2)
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
	source = client
	self.callback(unpack(self.cbArgs))
	
	prof:cp('RPC result')
end

addEventHandler('main.onRpc', resourceRoot, onRpc)
addEventHandler('main.onRpcResult', resourceRoot, onRpcResult)
