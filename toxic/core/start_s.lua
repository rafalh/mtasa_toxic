local g_InitFuncs = {}
local g_PreInitFuncs = {}
local _addEventHandler
local g_Co, g_CoTicks
local g_ScoreBoardRes = Resource('scoreboard')

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
		DbQuery('COMMIT')
		DbQuery('BEGIN')
		for i, upd in ipairs(Updater.list) do
			if(upd.ver > ver) then
				local err = upd.func()
				if(err) then
					outputDebugString('Database update ('..ver..' -> '..upd.ver..') failed: '..tostring(err), 1)
					DbQuery('ROLLBACK')
					DbQuery('BEGIN')
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
	
	for i, right in ipairs(AccessRight.list) do
		local rightName = right:getFullName()
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
	local node = xmlLoadFile('conf/countries.xml')
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local code = xmlNodeGetAttribute(subnode, 'code')
		local name = xmlNodeGetAttribute(subnode, 'name')
		assert(code and name)
		code = code:upper()
		name = upperCaseWords(name:lower())
		g_Countries[code] = name
	end
	
	xmlUnloadFile(node)
	return true
end

local function LoadLanguages()
	local node = xmlLoadFile('conf/iso_langs.xml')
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
	local node = xmlLoadFile('conf/map_types.xml')
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
	if(g_ScoreBoardRes:isReady()) then
		g_ScoreBoardRes:call('scoreboardAddColumn', 'country', g_Root, 50, 'Country', false, 'country_img')
		if(AvtSetupScoreboard) then
			AvtSetupScoreboard(g_ScoreBoardRes.res)
		end
		if(StSetupScoreboard) then
			StSetupScoreboard(g_ScoreBoardRes.res)
		end
	end
end

g_ScoreBoardRes:addReadyHandler(function()
	setTimer(setupScoreboard, 1000, 1)
end)

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
	
	for i, func in ipairs(g_PreInitFuncs) do
		func()
	end
	
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

function addPreInitFunc(func)
	assert(func)
	table.insert(g_PreInitFuncs, func)
end

addEventHandler('onResourceStart', g_ResRoot, init)

-- Disable addEventHandler for loading
_addEventHandler = addEventHandler
function addEventHandler(...)
	outputDebugString('addEventHandler is not recommended at startup! Use addInitFunc instead.', 2)
	DbgTraceBack()
	return _addEventHandler(...)
end
