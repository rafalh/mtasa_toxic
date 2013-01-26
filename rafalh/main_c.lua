--------------
-- Includes --
--------------

#include "include/internal_events.lua"

-------------------
-- Custom events --
-------------------

addEvent("onClientCall_race", true)

--------------------------------
-- Local function definitions --
--------------------------------

local function onClientThisResourceStart(res)
	local raceRes = getResourceFromName("race")
	if(raceRes and not triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "unbindKey", "k", "down")) then
		setTimer(function()
			local raceRes = getResourceFromName("race")
			if(raceRes) then
				triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "unbindKey", "k", "down")
			end
		end, 1000, 1)
	end
	
	loadSettings()
	
	if(not bindKey(g_ClientSettings.suicide_key, "down", suicide)) then
		g_ClientSettings.suicide_key = "k"
		bindKey("k", "down", suicide)
	end
	
	triggerServerInternalEvent($(EV_RAFALH_START), g_Me)
end

local function onClientResourceStart(res)
	if(getResourceName(res) == "race") then
		setTimer(function()
			local raceRes = getResourceFromName("race")
			if(raceRes) then
				triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "unbindKey", "k", "down")
			end
		end, 1000, 1)
	end
	
	if(g_Settings.lang) then
		triggerEvent("onClientLangChange", getResourceRootElement(res), g_Settings.lang)
	end
end

local function onClientThisResourceStop()
	local raceRes = getResourceFromName("race")
	if(raceRes) then
		triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "bindKey", "k", "down", "kill")
	end
end

local function onClientPlayerQuit(reason)
	local nick = getPlayerName(source):gsub("#%x%x%x%x%x%x", "")
	
	if(reason == "Kicked") then customMsg(255, 96, 96, "* %s has been kicked from the game.", nick)
	elseif(reason == "Banned") then customMsg(255, 96, 96, "* %s has been banned from the game.", nick)
	elseif(reason == "Quit") then customMsg(255, 96, 96, "* %s has left the game.", nick)
	else customMsg(255, 96, 96, "* %s has left the game [%s].", nick, reason) end
end

local function onClientInit(accountId, settings, isNew)
	g_MyId = accountId
	g_Settings = settings
	
	triggerEvent("onClientLangChange", g_Root, settings.lang)
	if(isNew) then
		customMsg(255, 96, 96, "Press %s to open User Panel and %s to open Statistics Panel!", g_ClientSettings.user_panel_key, g_ClientSettings.stats_panel_key)
	end
end

local function clearChat()
	local chatLayout = getChatboxLayout()
	for i = 1, chatLayout.chat_lines do
		outputChatBox("")
	end
end

addCommandHandler("clearchat", clearChat, false)

------------
-- Events --
------------

addEventHandler("onClientResourceStart", g_Root, onClientResourceStart)
addEventHandler("onClientResourceStart", g_ResRoot, onClientThisResourceStart)
addEventHandler("onClientResourceStop", g_ResRoot, onClientThisResourceStop)
addEventHandler("onClientPlayerQuit", g_Root, onClientPlayerQuit)
addInternalEventHandler($(EV_CLIENT_INIT), onClientInit)
addInternalEventHandler($(EV_SET_GRAVITY), setGravity)
