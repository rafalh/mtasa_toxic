-- Options
#ENCRYPT = false
#ENCRYPTION_KEY = 'key!'
#DEBUG_PERF = true

-- Includes
#include 'include/nativeFunction.lua'
#include 'include/decrypt.lua'
#if(ENCRYPT) then
#  load 'include/encrypt.lua'
#end

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

-- Check if functions are hooked
if(not areNativeFunctions(f)) then return end

local EvVerifierReady = 'AOGltgWlbU'
local EvVerifyReq = 'YSRDCiwdyY'
local EvVerified = '0CqFvjg0uc'
local EvResStart = triggerClientEvent and 'onResourceStart' or 'onClientResourceStart'

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
		
#if(DEBUG_PERF) then
		local startTicks = getTickCount()
#end
		
#if(ENCRYPT) then
		local code = {
# local LUA_CHUNK = __LUA_CHUNK_TBL__
# for i, part in ipairs(LUA_CHUNK) do
#	part = encrypt(part, ENCRYPTION_KEY)
	$(('%q'):format(part)),
# end
		}
#else
		local code = __LUA_CHUNK_TBL__
#end
		
		local i = 0
		local function reader()
			i = i + 1
#if(ENCRYPT) then
			return decrypt(code[i], '$(ENCRYPTION_KEY)')
#else
			return code[i]
#end
		end
		
		--outputDebugString('Loading code ('..getResourceName(resource)..' - '..side..')')
		local func, err = f.load(reader)
		if(not func) then
			outputDebugString('Failed to load '..getResourceName(resource)..': '..err, 1)
			return
		end
		
#if(DEBUG_PERF) then
		local dt = getTickCount() - startTicks
		if(dt > 50) then
			outputDebugString('Loading '..getResourceName(resource)..' ('..side..') has taken '..dt..' ms!', 3)
		end
#end
		
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
