local function isNativeFunction(func)
	local info = debug.getinfo(func, 'S')
	return info.what == 'C'
end

local f = {
	rnd = math.random,
	loadstr = loadstring,
	load = load,
	md5 = md5,
	addEvent = addEvent,
	addEventHandler = addEventHandler,
	removeEventHandler = removeEventHandler,
	triggerEvent = triggerEvent,
}

for i, f in pairs(f) do
	if(not isNativeFunction(f)) then return end
end

local EvVerifierReady = 'AOGltgWlbU'
local EvVerifyReq = 'YSRDCiwdyY'
local EvVerified = '0CqFvjg0uc'
local EvResStart = triggerClientEvent and "onResourceStart" or "onClientResourceStart"

local g_ResStarted = false

f.addEvent(EvVerifierReady)
f.addEvent(EvVerifyReq)
f.addEvent(EvVerified)

local tryVerify
tryVerify = function()
	--outputDebugString('tryVerify')
	local n = f.rnd(0, 32000)
	local onVerified
	onVerified = function(code)
		if(code ~= f.md5('8_ccDr-8'..tostring(n^2+93))) then return end
		
		f.removeEventHandler(EvVerifierReady, root, tryVerify)
		local side = triggerClientEvent and 'server' or 'client'
		--outputDebugString('Server verified ('..getResourceName(resource)..' - '..side..')')
		
		--loadScript = function()
		--outputDebugString('Timer proc start')
		-- Hook addEventHandler to catch all onResourceStart handlers
		local initFuncTbl = {}
		if(g_ResStarted) then
			local _addEventHandler = addEventHandler
			addEventHandler = function(event, element, func, ...)
				_addEventHandler(event, element, func, ...)
				if(event == EvResStart and (element == root or element == resourceRoot)) then
					table.insert(initFuncTbl, func)
				end
			end
		end
		
		local code = %s
		local i = 0
		local function reader()
			i = i + 1
			return code[i]
		end
		
		--outputDebugString('Loading code ('..getResourceName(resource)..' - '..side..')')
		local func, err = f.load(reader)
		if(not func) then
			outputDebugString('Failed to load '..getResourceName(resource)..': '..err, 1)
			return
		end
		
		--outputDebugString('Running code ('..getResourceName(resource)..' - '..side..')')
		func()
		
		-- Call onResourceStart handlers
		--outputDebugString('Calling '..#initFuncTbl..' initializers ('..side..')')
		source = resourceRoot
		for i, func in ipairs(initFuncTbl) do
			func(resource)
		end
		--outputDebugString('Finished loading '..getResourceName(resource)..' - '..side)
		--end
		--setTimer(loadScript, 50, 1)
		--outputDebugString('Created timer')
	end
	
	f.addEventHandler(EvVerified, resourceRoot, onVerified)
	f.triggerEvent(EvVerifyReq, resourceRoot, n)
	f.removeEventHandler(EvVerified, resourceRoot, onVerified)
end

local function onResStart()
	g_ResStarted = true
	f.addEventHandler(EvVerifierReady, root, tryVerify)
	tryVerify()
end

f.addEventHandler(EvResStart, resourceRoot, onResStart)
