--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

----------------------
-- Global variables --
----------------------

g_Me = getLocalPlayer()
g_MyId = 0
g_ScreenSize = {guiGetScreenSize()}
g_InternalEventHandlers = {}

---------------------
-- Local variables --
---------------------

local g_ThisRes = getThisResource()
local g_ThisResName = getResourceName(g_ThisRes)

-------------------
-- Custom events --
-------------------

addEvent('onEvent_'..g_ThisResName, true)

--------------------------------
-- Local function definitions --
--------------------------------

local function onEventHandler(event, ...)
	if(sourceResource) then -- HACKFIX: sourceResource is nil after r5937
		if(sourceResource ~= g_ThisRes) then
			outputDebugString('Access denied', 2)
		end
	else
		--outputDebugString('onEventHandler: sourceResource is nil (event '..tostring(event)..')', 2)
	end
	if(g_InternalEventHandlers[event or false]) then
		for _, handler in ipairs(g_InternalEventHandlers[event]) do
			handler(...)
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function findPlayer(str)
	if(not str) then
		return false
	end
	
	local player = getPlayerFromName(str)
	if(player) then
		return player
	end
	
	local str_lower = str:lower()
	for i, player in ipairs(getElementsByType('player')) do
		local name = getPlayerName(player):gsub('#%x%x%x%x%x%x', ''):lower()
		if(name:find(str_lower, 1, true)) then
			return player
		end
	end
	
	return false
end

function addInternalEventHandler(eventtype, handler)
	assert(eventtype)
	if(not g_InternalEventHandlers[eventtype]) then
		g_InternalEventHandlers[eventtype] = {}
	end
	table.insert(g_InternalEventHandlers[eventtype], handler)
end

function triggerServerInternalEvent(eventtype, source, ...)
	assert(eventtype)
	-- Note: unpack must be last arg
	triggerServerEvent('onEvent_'..g_ThisResName, source, eventtype, unpack({ ... }))
end

function triggerInternalEvent(eventtype, source, ...)
	assert(eventtype)
	
	if(g_InternalEventHandlers[eventtype]) then
		for i, handler in ipairs(g_InternalEventHandlers[eventtype]) do
			handler(...)
		end
	end
end

_isPlayerDead = isPlayerDead
function isPlayerDead(player)
	local state = getElementData(player, 'state')
	if(not state) then
		return _isPlayerDead(player)
	end
	return (state ~= 'alive')
end

local g_DelayedList = {}

local function delayedTick()
	removeEventHandler('onClientPreRender', root, delayedTick)
	for i, info in ipairs(g_DelayedList) do
		local status, err = pcall(unpack(info))
		if(not status) then
			outputDebugString('Delayed call failed: '..err, 1)
		end
	end
	g_DelayedList = {}
end

function delayExecution(fn, ...)
	table.insert(g_DelayedList, {fn, ...})
	if(#g_DelayedList == 1) then
		addEventHandler('onClientPreRender', root, delayedTick)
	end
end

------------
-- Events --
------------

addEventHandler('onEvent_'..g_ThisResName, g_Root, onEventHandler)
