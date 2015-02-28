local g_InitCallbacks = {}
local g_PreInitFuncs = {}
local _addEventHandler
local g_Co, g_CoTicks
local g_ScoreBoardRes

#DBG_START_PERF = false

local function setupDatabase()
	if (not DbInit()) then
		return false
	end
	
	if (not Settings.init()) then
		return false
	end
	
	if (not Updater.run()) then
		return false
	end
	
	return true
end

local function cleanUpDatabase()
	if (not Settings.cleanup_done) then
		Debug.warn('Cleaning database!')
		DbQuery('UPDATE '..DbPrefix..'players SET online=0')
	end
	Settings.cleanup_done = false
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

local function setupScoreboard()
	if (g_ScoreBoardRes:isReady()) then
		g_ScoreBoardRes:call('scoreboardAddColumn', 'country', g_Root, 50, 'Country', false, 'country_img')
		if (AvtSetupScoreboard) then
			AvtSetupScoreboard(g_ScoreBoardRes.res)
		end
		if (StSetupScoreboard) then
			StSetupScoreboard(g_ScoreBoardRes.res)
		end
	end
end

local function initPlayers()
	for i, playerEl in ipairs (getElementsByType('player')) do
		if (NbCheckPlayerAndFix) then
			NbCheckPlayerAndFix(playerEl)
		end
		
		Player.create(playerEl)
	end
	
	local consoles = getElementsByType('console')
	assert(#consoles == 1)
	Player.create(consoles[1])
end

local function initRountine()
	table.sort(g_InitCallbacks, function(a, b)
		return a[2] < b[2]
	end)
	
	local prof = DbgPerf(300)
	
	for i, data in ipairs(g_InitCallbacks) do
		local func = data[1]
#if(DBG_START_PERF) then
		local name = data[3]
		local prof2 = DbgPerf()
		func()
		prof2:cp(name)
#else
		func()
#end
	end
	
	prof:cp('init')
	Debug.info('rafalh script has started!')
#if(TEST) then
	Debug.warn('Script compiled with test support')
#end

end

function continueCoRountine(notFirst)
	while(getTickCount() - g_CoTicks < 2000 and coroutine.status(g_Co) ~= 'dead') do
		local success, msg = coroutine.resume(g_Co)
		if(not success) then
			Debug.warn('Worker failed: '..msg)
			if(not notFirst) then
				cancelEvent()
			end
			return false
		end
	end
	
	if(coroutine.status(g_Co) ~= 'dead') then
		if(not notFirst) then
			Debug.info('Please wait while script is initializing...')
		else
			Debug.info('Still working... Please wait.')
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

function addInitFunc(func, prio)
	assert(func)
#if(DBG_START_PERF) then
	local name = Debug.getStackTrace(1, 1)[1]
	table.insert(g_InitCallbacks, {func, prio or 0, name})
#else
	table.insert(g_InitCallbacks, {func, prio or 0})
#end
	
end

addEventHandler('onResourceStart', resourceRoot, init)

-- Disable addEventHandler for loading
_addEventHandler = addEventHandler
function addEventHandler(...)
	Debug.warn('addEventHandler is not recommended at startup! Use addInitFunc instead.')
	Debug.printStackTrace()
	return _addEventHandler(...)
end

addInitFunc(setupDatabase, -200)
addInitFunc(cleanUpDatabase, -190)
addInitFunc(initPlayers, -100)

addInitFunc(LoadCountries, -10)
addInitFunc(LoadLanguages, -10)

addInitFunc(function()
	g_ScoreBoardRes = Resource('scoreboard')
	setupScoreboard()
	g_ScoreBoardRes:addReadyHandler(function()
		setTimer(setupScoreboard, 1000, 1)
	end)
end)
