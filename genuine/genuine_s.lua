-- Includes
#include '../include/obfuscation.lua'
#include '../include/nativeFunction.lua'
#include '../include/verification.lua'
#include '../include/encrypt.lua'

-- Variables
local g_Valid = false
local g_Fails = 0
local f = {
	random = math.random,
	getTickCount = getTickCount,
	fetchRemote = fetchRemote,
	stopResource = stopResource,
	getThisResource = getThisResource,
	cancelEvent = cancelEvent,
	addEventHandler = addEventHandler,
	triggerEvent = triggerEvent,
	triggerClientEvent = triggerClientEvent,
	md5 = md5,
	setTimer = setTimer,
	getServerName = getServerName,
	getServerPassword = getServerPassword,
	sethook = debug.sethook,
}

-- Events
addEvent('txgenuine.onKeyReq', true)

local function fileGetContents(path)
	local file = fileOpen(path, true)
	if (not file) then
		outputDebugString('Failed to open '..path, 2)
		return false
	end
	
	local size = fileGetSize(file)
	local buf = size > 0 and fileRead(file, size) or ''
	fileClose(file)
	
	return buf
end

#TEST_CIPHER = false
#if(TEST_CIPHER) then
#	include '../include/decrypt.lua'
#	include '../include/randomStr.lua'

	local rnd1 = genRandomStr(10)
	local rnd2 = genRandomStr(10)
	local rnd3 = genRandomStr(17)
	local rnd4 = genRandomStr(7)
	assert(encrypt(rnd1, '\0\0\0\0\0\0') == rnd1)
	assert(decrypt(encrypt(rnd1, rnd2), rnd2) == rnd1)
	assert(decrypt(encrypt(rnd1, rnd3), rnd3) == rnd1)
	assert(decrypt(encrypt(rnd1, rnd4), rnd4) == rnd1)
#end

local function callback(responseData, errno, n)
	if(responseData == 'ERROR') then
		outputDebugString('fetchRemote failed: '..errno, 2)
		g_Fails = g_Fails + 1
		return
	end
	
	g_Fails = 0
	
	local fmt = $(OBFUSCATE('yay%uok'))
	if(responseData == md5(fmt:format(n))) then
		g_Valid = true -- OK
	else
		local fmt = $(OBFUSCATE('Verification failed: %s!'))
		outputDebugString(fmt:format(responseData), 2)
		g_Valid = false
	end
end

local function urlEncode(str)
	-- Don't use urlEncode from utils because it can be hooked
	return str:gsub('[^%w%.%-_ ]', function(ch)
		return ('%%%02X'):format(ch:byte())
	end):gsub(' ', '+')
end

local function checkOnline()
	local n = f.random(1, 65000)
	local pw = f.getServerPassword()
	local name = f.getServerName()
	local urlFmt = $(OBFUSCATE('http://ravin.tk/api/mta/checkserial.php?serial=%s&name=%s&pw=%s&n=%u'))
	local url = urlFmt:format(
		g_Serial, urlEncode(name), pw and '1' or '0', n)
	if(not f.fetchRemote(url, callback, '', false, n)) then
		-- Access denied
		g_Valid = false
	end
end

local function checkSerial(serial)
	local fmt = $(OBFUSCATE('Toxic%04XFriendshipIsMagic'))
	for i = 0, 0xFFFF do
		if(f.md5(fmt:format(i)) == serial) then
			return true
		end
	end
	return false
end

local function onKeyReq(tempKey)
	if(type(tempKey) ~= "string") then return end
	local key = encrypt($(SERV_VERIFICATION_KEY), tempKey)
	f.triggerClientEvent(client, 'txgenuine.onKey', resourceRoot, key)
end

local function onVerifyReq(n)
	--outputDebugString('Verify Request '..n)
	n = tonumber(n)
	if(g_Valid and n) then
		local code = f.md5($(SERV_VERIFICATION_KEY)..tostring(n^2+93))
		f.triggerEvent($(EV_VERIFIED), source, code)
	end
end

local function init()
	-- Init random generator
	math.randomseed(f.getTickCount())
	
	g_Serial = fileGetContents('serial.txt')
	if(not g_Serial) then return end
	
	local hack = false
	
	-- Remove hooks if there is any
	f.sethook()
	
	-- Check if functions are hooked
	if(not areNativeFunctions(f)) then
		hack = true
	end
	
	if(not checkSerial(g_Serial)) then
		hack = true
	end
	
	if(hack) then
		f.cancelEvent(true, $(OBFUSCATE('Hacking attempt')))
		return
	end
	
	-- Allow resources to start
	g_Valid = true
	
	-- Begin online checks
	checkOnline()
	local sec = 24*3600 + f.random(-3600, 3600) -- randomize check a bit
	f.setTimer(checkOnline, sec*1000, 0)
	
	f.addEventHandler('txgenuine.onKeyReq', resourceRoot, onKeyReq)
	f.addEventHandler($(EV_VERIFY_REQ), root, onVerifyReq)
	f.triggerEvent($(EV_VERIFIER_READY), resourceRoot)
end

addEventHandler('onResourceStart', resourceRoot, init)
