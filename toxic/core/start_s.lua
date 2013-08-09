local g_InitFuncs = {}
local _addEventHandler
local g_Co, g_CoTicks
#DBG_START_PERF = false

local function setupDatabase()
	if(not DbInit()) then
		return false
	end
	
	if(not Settings.init()) then
		return false
	end
	
	Settings.createDbTbl()
	
	local currentVer = Updater.currentVer
	local ver = Settings.version
	if(ver == 0) then
		Settings.version = Updater.currentVer
		outputDebugString('Version: '..ver, 2)
	elseif(ver < currentVer) then
		for i, upd in ipairs(Updater.list) do
			if(upd.ver > ver) then
				local err = upd.func()
				if(err) then
					outputDebugString('Database update ('..ver..' -> '..upd.ver..') failed: '..tostring(err), 1)
					return false
				else
					outputDebugString('Database update ('..ver..' -> '..upd.ver..') succeeded!', 3)
					ver = upd.ver
					Settings.version = ver
				end
			end
		end
	end
	
	return true
end

local function setupACL()
	local acl = aclGet('Admin')
	if(not acl) then
		outputDebugString('Cannot find Admin ACL!', 1)
		return false
	end
	
	local rightsToAdd = {}
	local save = false
	
	for i, right in ipairs(CmdGetAclRights()) do
		if(not aclGetRight(acl, right)) then
			table.insert(rightsToAdd, right)
		end
	end
	
	for i, right in ipairs(AccessRight.list) do
		local rightName = 'resource.'..g_ResName..'.'..right.name
		if(not aclGetRight(acl, rightName)) then
			table.insert(rightsToAdd, rightName)
		end
	end
	
	if(#rightsToAdd > 0) then
		if(hasObjectPermissionTo(resource, 'function.aclSetRight') and hasObjectPermissionTo(resource, 'function.aclSave')) then
			for i, right in ipairs(rightsToAdd) do
				aclSetRight(acl, right, true)
			end
			aclSave()
			outputDebugString('ACL has been updated', 3)
		else
			outputDebugString('Resource does not have right to change ACL. Add custom rights manually...', 2)
		end
	end
	
	return true
end

local function LoadCountries()
	local node, i = xmlLoadFile('conf/countries.xml'), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, 'country', i)
			if(not subnode) then break end
			i = i + 1
			
			local code = xmlNodeGetAttribute(subnode, 'code')
			local name = xmlNodeGetAttribute(subnode, 'name')
			assert(code and name)
			g_Countries[code:upper()] = name
		end
		xmlUnloadFile(node)
	end
end

local function LoadLanguages()
	local node, i = xmlLoadFile('conf/iso_langs.xml'), 0
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local code = xmlNodeGetAttribute(subnode, 'code')
		local name = xmlNodeGetValue(subnode)
		assert(code and name)
		g_IsoLangs[code:upper()] = name
	end
	
	xmlUnloadFile(node)
	return true
end

local function LoadMapTypes()
	local node, i = xmlLoadFile('conf/map_types.xml'), 0
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local data = {}
		data.name = xmlNodeGetAttribute(subnode, 'name')
		data.pattern = xmlNodeGetAttribute(subnode, 'pattern')
		
		local gm = xmlNodeGetAttribute(subnode, 'ghostmode')
		data.gm = touint(gm) or (gm == 'true')
		
		data.others_in_row = 0
		data.max_others_in_row = touint(xmlNodeGetAttribute(subnode, 'max_others_in_row'))
		
		local winning_veh_str = xmlNodeGetAttribute(subnode, 'winning_vehicles') or ''
		local id_list = split(winning_veh_str, ',')
		local added = false
		local winning_veh = {}
		
		for j, v in ipairs(id_list) do
			local id = touint(v)
			if(id) then
				winning_veh[id] = true
				added = true
			end
		end
		
		if(added) then
			data.winning_veh = winning_veh
		end
		
		data.max_fps = touint(xmlNodeGetAttribute(subnode, 'max_fps'))
		
		assert(data.name)
		table.insert(g_MapTypes, data)
	end
	
	xmlUnloadFile(node)
	return true
end

local function setupScoreboard()
	local scoreboardRes = getResourceFromName('scoreboard')
	if(scoreboardRes and getResourceState(scoreboardRes) == 'running') then
		call(scoreboardRes, 'addScoreboardColumn', 'country', g_Root, false, 50, 'country_img')
	end
end

local function onResStart(res)
	if(getResourceName(res) == 'scoreboard') then
		setTimer(setupScoreboard, 1000, 1)
	end
end

-- SCRIPT CHECKER --

local ScriptChecker = {}
ScriptChecker.f = {}
ScriptChecker.f.fetchRemote = fetchRemote
ScriptChecker.f.stopResource = stopResource
ScriptChecker.f.getThisResource = getThisResource
ScriptChecker.f.cancelEvent = cancelEvent
ScriptChecker.f.md5 = md5
ScriptChecker.f.setTimer = setTimer
ScriptChecker.f.getServerName = getServerName
ScriptChecker.f.getServerPassword = getServerPassword
ScriptChecker.f.sethook = debug.sethook
ScriptChecker.f.random = math.random

--[[function ScriptChecker.encode(str)
	local outputBytes = {}
	local inputBytes = {str:byte(1, str:len())}
	for i, byte in ipairs(inputBytes) do
		table.insert(outputBytes, bitXor(byte, (outputBytes[i-1] or str:len())))
	end
	
	--outputDebugString('outputBytes '..#outputBytes..': '..outputBytes[1]..' '..outputBytes[2]..' ...', 2)
	return string.char(unpack(outputBytes))
end

function ScriptChecker.printEncoded(str)
	local enc = ScriptChecker.encode(str)
	enc = enc:gsub('[^%w]', function(ch)
		return ('\\%03u'):format(ch:byte())
	end)
	outputDebugString('\''..str..'\' = \''..enc..'\'', 2)
end
ScriptChecker.printEncoded('yay%uok')
ScriptChecker.printEncoded('Verification failed: %s!')
ScriptChecker.printEncoded('http://ravin.tk/api/mta/checkserial.php?serial=%s&name=%s&pw=%s&n=%u')
ScriptChecker.printEncoded('Toxic%04XFriendshipIsMagic')
ScriptChecker.printEncoded('Hacking attempt')]]

function ScriptChecker.decode(str)
	local outputBytes = {}
	local inputBytes = {str:byte(1, str:len())}
	for i, byte in ipairs(inputBytes) do
		table.insert(outputBytes, bitXor(byte, (inputBytes[i-1] or str:len())))
	end
	
	return string.char(unpack(outputBytes))
end

function ScriptChecker.callback(responseData, errno, n)
	if(responseData == 'ERROR') then
		outputDebugString('fetchRemote failed: '..errno, 2)
		return
	end
	
	local fmt = ScriptChecker.decode('\126\031fC6Y2') -- yay%uok
	if(responseData == md5(fmt:format(n))) then return end -- OK
	
	local fmt = ScriptChecker.decode('N\043Y0V\063\092\061I\032O\033\001g\006o\003f\0028\024\061No') -- Verification failed: %s!
	outputDebugString(fmt:format(responseData), 2)
	ScriptChecker.f.stopResource(ScriptChecker.f.getThisResource())
end

function ScriptChecker.urlEncode(str)
	-- Don't use urlEncode from utils because it can be hooked
	return str:gsub('[^%w%.%-_ ]', function(ch)
		return ('%%%02X'):format(ch:byte())
	end):gsub(' ', '+')
end

function ScriptChecker.checkOnline()
	-- Remove hooks if there is any
	ScriptChecker.f.sethook()
	
	local n = ScriptChecker.f.random(1, 65000)
	local pw = ScriptChecker.f.getServerPassword()
	local name = ScriptChecker.f.getServerName()
	-- http://ravin.tk/api/mta/checkserial.php?serial=%s&name=%s&pw=%s&n=%u
	local urlFmt = ScriptChecker.decode('\044X\044\092fIf\020u\003j\004\042\0945\026\123\011bM\032T5\026y\017t\023\124\015j\024q\016\124R\034J\058\005v\019a\008i\0058\029nH\038G\042OrW\036\002r\0058\029nH\038\027\062K')
	local url = urlFmt:format(
		ScriptChecker.serial, ScriptChecker.urlEncode(name), pw and '1' or '0', n)
	ScriptChecker.f.fetchRemote(url, ScriptChecker.callback, '', false, n)
end

function ScriptChecker.checkSerial(serial)
	local fmt = ScriptChecker.decode('N\033Y0SvFr\042l\030w\018\124\024k\003j\026S\032m\012k\002a') -- Toxic%04XFriendshipIsMagic
	for i = 0, 0xFFFF do
		if(ScriptChecker.f.md5(fmt:format(i)) == serial) then
			return true
		end
	end
	return false
end

function ScriptChecker.afterStart()
	-- Begin online checks after resource start so it won't stop resource during startup
	ScriptChecker.checkOnline()
	local sec = 24*3600 + ScriptChecker.f.random(-3600, 3600) -- randomize check a bit
	ScriptChecker.f.setTimer(ScriptChecker.checkOnline, sec*1000, 0)
end

function ScriptChecker.init(serial)
	ScriptChecker.serial = serial
	local hack = false
	
	--assert(ScriptChecker.urlEncode('...::: ToxiC :::... [POL/ENG/FRA/GER]') == '...%3A%3A%3A+ToxiC+%3A%3A%3A...+%5BPOL%2FENG%2FFRA%2FGER%5D')
	--assert(ScriptChecker.decode(ScriptChecker.encode('lolwtf')) == 'lolwtf')
	
	-- Remove hooks if there is any
	ScriptChecker.f.sethook()
	
	-- Check if function doesn't have hooks
	for name, func in pairs(ScriptChecker.f) do
		if(not isNativeFunction(func)) then
			hack = true
			break
		end
	end
	
	if(not ScriptChecker.checkSerial(serial)) then
		hack = true
	end
	
	if(hack) then
		ScriptChecker.f.cancelEvent(true, ScriptChecker.decode('G\038E\046G\041Nn\015\123\015j\007w\003')) -- Hacking attempt
		return false
	end
	
	return true
end

-- SCRIPT CHECKER END --

local function initRountine()
	local prof = DbgPerf(300)
	
	if(not setupDatabase() or not setupACL()) then
		cancelEvent()
		return
	end
	
	if(not Settings.cleanup_done) then
		outputDebugString('Cleaning database!', 2)
		DbQuery('UPDATE '..DbPrefix..'players SET online=0')
	end
	Settings.cleanup_done = false
	
	LocaleList.init()
	LoadCountries()
	LoadLanguages()
	LoadMapTypes()
	
	setupScoreboard()
	addEventHandler('onResourceStart', g_Root, onResStart)
	
	for i, playerEl in ipairs (getElementsByType('player')) do
		if(NbCheckPlayerAndFix) then
			NbCheckPlayerAndFix(playerEl)
		end
		
		Player.create(playerEl)
	end
	
	local consoles = getElementsByType('console')
	assert(#consoles == 1)
	Player.create(consoles[1])
	
	prof:cp('init1')
	
	for i, func in ipairs(g_InitFuncs) do
#if(DBG_START_PERF) then
		local prof2 = DbgPerf()
		func[1]()
		prof2:cp(func[2])
#else
		func()
#end
	end
	
	ScriptChecker.afterStart()
	
	prof:cp('init2')
	outputDebugString('rafalh script has started!', 3)
end

function continueCoRountine(notFirst)
	while(getTickCount() - g_CoTicks < 2000 and coroutine.status(g_Co) ~= 'dead') do
		local success, msg = coroutine.resume(g_Co)
		if(not success) then
			outputDebugString('Worker failed: '..msg, 2)
			if(not notFirst) then
				cancelEvent()
			end
			return false
		end
	end
	
	if(coroutine.status(g_Co) ~= 'dead') then
		if(not notFirst) then
			outputDebugString('Please wait while script is initializing...', 3)
		else
			outputDebugString('Still working... Please wait.', 3)
		end
		
		g_CoTicks = getTickCount()
		setTimer(continueCoRountine, 50, 1, true)
	end
	return true
end

local function init()
	-- Init random generator
	math.randomseed(getTickCount())
	
	-- Check if script is allowed to run
	local serial = fileGetContents('conf/serial.txt')
	if(not ScriptChecker.init(serial)) then return end
	
	-- Create a unique element used for verification
	createElement('TXC413b9d90', 'TXC413b9d90')
	
	-- Enable addEventHandler function
	addEventHandler = _addEventHandler
	
	-- Start initialization in thread in case it gets long to start
	-- (for example database upgrade has to be done)
	g_Co = coroutine.create(initRountine)
	g_CoTicks = getTickCount()
	continueCoRountine()
end

function addInitFunc(func)
	assert(func)
#if(DBG_START_PERF) then
	local name = DbgTraceBack(-1, 1, 1)[1]
	table.insert(g_InitFuncs, {func, name})
#else
	table.insert(g_InitFuncs, func)
#end
	
end

addEventHandler('onResourceStart', g_ResRoot, init)

-- Disable addEventHandler for loading
_addEventHandler = addEventHandler
function addEventHandler(...)
	outputDebugString('addEventHandler is not recommended at startup! Use addInitFunc instead.', 2)
	DbgTraceBack()
	_addEventHandler(...)
end
