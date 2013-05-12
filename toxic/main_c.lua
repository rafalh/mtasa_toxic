--------------
-- Includes --
--------------

#include "include/internal_events.lua"

Styles = {
	joinQuit = {"#00BB00", "#EEEEEE"},
	help = {"#FF6464", "#EEEEEE"},
	pm = "#FF6060",
}

g_Ready = false

-------------------
-- Custom events --
-------------------

addEvent("main.onAccountChange", true)

--------------------------------
-- Local function definitions --
--------------------------------

local function init(res)
	Settings.load()
	
	triggerServerEvent("main.onPlayerReady", g_ResRoot, Settings.locale)
end

local function onPlayerQuit(reason)
	local nick = getPlayerName(source):gsub("#%x%x%x%x%x%x", "")
	
	if(reason == "Kicked") then outputMsg(Styles.joinQuit, "* %s has been kicked from the game.", nick)
	elseif(reason == "Banned") then outputMsg(Styles.joinQuit, "* %s has been banned from the game.", nick)
	elseif(reason == "Quit") then outputMsg(Styles.joinQuit, "* %s has left the game.", nick)
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
	triggerEvent("onClientLangChange", g_Root, localeId)
	g_Ready = true
	
	if(isNew) then
		local userPanelKey = getKeyBoundToCommand("UserPanel") or "-"
		local statsPanelKey = getKeyBoundToCommand("StatsPanel") or "-"
		outputMsg(Styles.help, "Press %s to open User Panel and %s to open Statistics Panel!", userPanelKey, statsPanelKey)
	end
end

local function clearChat()
	local chatLayout = getChatboxLayout()
	for i = 1, chatLayout.chat_lines do
		outputChatBox("")
	end
	
outputMsg(Styles.joinQuit, "%s has been kicked from the game.", "TEST")
end

addCommandHandler("clearchat", clearChat, false)

------------
-- Events --
------------

addEventHandler("onClientResourceStart", g_ResRoot, init)
addEventHandler("onClientPlayerQuit", g_Root, onPlayerQuit)
addEventHandler("main.onAccountChange", g_ResRoot, onAccountChange)
addInternalEventHandler($(EV_CLIENT_INIT), onClientInit)
