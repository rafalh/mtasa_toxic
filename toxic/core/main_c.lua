-- Includes
#include 'include/internal_events.lua'

-- Global variables
Styles = {
	joinQuit = {'#00BB00', '#EEEEEE'},
	help = {'#FF6464', '#EEEEEE'},
	pm = '#FF6060',
	red = {'#FF0000', '#EEEEEE'},
	green = {'#00FF00', '#EEEEEE'},
	yellow = {'#FFFF00', '#EEEEEE'},
}
g_Init = true

-- Custom events
addEvent('main.onAccountChange', true)

-- Functions

local function init(res)
	guiSetInputMode('no_binds_when_editing')
	Settings.load()
	
	triggerServerEvent('main.onPlayerReady', g_ResRoot, Settings.locale)
end

local function onPlayerQuit(reason)
	local nick = getPlayerName(source)
	
	if(reason == 'Kicked') then outputMsg(Styles.joinQuit, "* %s has been kicked from the game.", nick)
	elseif(reason == 'Banned') then outputMsg(Styles.joinQuit, "* %s has been banned from the game.", nick)
	elseif(reason == 'Quit') then outputMsg(Styles.joinQuit, "* %s has left the game.", nick)
	else outputMsg(Styles.joinQuit, "* %s has left the game [%s].", nick, reason) end
end

local function onAccountChange(accountName, accountId)
	g_UserName = accountName
	g_MyId = accountId
end

local function onClientInit(accountId, settings, isNew, localeId)
	g_MyId = accountId
	Settings.setGlobal(settings)
	Settings.locale = localeId
	triggerEvent('onClientLangChange', g_Root, localeId)
	
	if(isNew) then
		local userPanelKey = getKeyBoundToCommand('UserPanel') or '-'
		local statsPanelKey = getKeyBoundToCommand('StatsPanel') or '-'
		outputMsg(Styles.help, "Press %s to open User Panel and %s to open Statistics Panel!", userPanelKey, statsPanelKey)
	end
	
	g_Init = false
end

------------
-- Events --
------------

addEventHandler('onClientResourceStart', g_ResRoot, init)
addEventHandler('onClientPlayerQuit', g_Root, onPlayerQuit)
addEventHandler('main.onAccountChange', g_ResRoot, onAccountChange)
addInternalEventHandler($(EV_CLIENT_INIT), onClientInit)
