-- Includes
#include '../include/nativeFunction.lua'
#include '../include/verification.lua'
#include '../include/randomStr.lua'
#include '../include/decrypt.lua'

-- Variables
local g_VerificationKey = false
local f = {
	random = math.random,
	rndseed = math.randomseed,
	getTickCount = getTickCount,
	md5 = md5,
	addEventHandler = addEventHandler,
	triggerServerEvent = triggerServerEvent,
	triggerEvent = triggerEvent,
}

-- Events
addEvent('txgenuine.onKey', true)

local function onVerifyReq(n)
	--outputDebugString('Verify Request '..n)
	n = tonumber(n)
	if(n) then
		local code = f.md5(g_VerificationKey..tostring(n^2+93))
		f.triggerEvent($(EV_VERIFIED), source, code)
	end
end

local function init()
	-- Init random generator
	f.rndseed(f.getTickCount())
	
	-- Check if functions are hooked
	if(not areNativeFunctions(f)) then return end
	
	-- Ask server for the key
	local temp = genRandomStr(8)
	local onKey = function(keyEnc)
		g_VerificationKey = decrypt(keyEnc, temp)
		--outputDebugString('Verification Key '..g_VerificationKey)
		
		f.addEventHandler($(EV_VERIFY_REQ), root, onVerifyReq)
		f.triggerEvent($(EV_VERIFIER_READY), resourceRoot)
	end
	f.addEventHandler('txgenuine.onKey', resourceRoot, onKey)
	f.triggerServerEvent('txgenuine.onKeyReq', resourceRoot, temp)
end

f.addEventHandler('onClientResourceStart', resourceRoot, init)
