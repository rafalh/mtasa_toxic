-- Includes
#include 'include/internal_events.lua'

local g_InitCallbacks = {}
local _addEventHandler

g_InitPhase = 0
g_Init = true
g_SharedState = {}

function addInitFunc(func, prio)
	assert(func)
	table.insert(g_InitCallbacks, {func, prio or 0})
end

local function runInitCallbacks(minPrio, maxPrio)
	-- Sort init callbacks
	table.sort(g_InitCallbacks, function(a, b)
		return a[2] < b[2]
	end)
	
	-- Call init callbacks in order
	for i, data in ipairs(g_InitCallbacks) do
		local func = data[1]
		local prio = data[2]
		if ((not minPrio or prio >= minPrio) and (not maxPrio or prio <= maxPrio)) then
			func()
		end
	end
end

local function onClientInit(accountId, settings, isNew, localeId)
	g_InitPhase = 2
	
	g_SharedState.accountId = accountId
	g_SharedState.newPlayer = isNew
	
	Settings.setGlobal(settings)
	Settings.locale = localeId
	triggerEvent('onClientLangChange', g_Root, localeId)
	
	runInitCallbacks(-10, false)
	
	g_Init = false
	g_InitPhase = 3
end

local function preInit()
	guiSetInputMode('no_binds_when_editing')
	
	-- Enable old addEventHandler
	addEventHandler = _addEventHandler
	
	g_InitPhase = 1
	runInitCallbacks(false, -11)
	Settings.load()
	
	addInternalEventHandler($EV_CLIENT_INIT, onClientInit)
	
	local sharedSettings = Settings.getShared()
	triggerServerEvent('main.onPlayerReady', g_ResRoot, sharedSettings)
end

addEventHandler('onClientResourceStart', resourceRoot, preInit)

-- Disable addEventHandler for loading
_addEventHandler = addEventHandler
function addEventHandler(...)
	outputDebugString('addEventHandler is not recommended at startup! Use addInitFunc instead.', 1)
	if (Debug) then
		Debug.printStackTrace()
	end
	return _addEventHandler(...)
end
