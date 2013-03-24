--------------
-- Includes --
--------------

#include "include/internal_events.lua"

-------------------
-- Custom events --
-------------------

addEvent("onClientCall_race", true)
addEvent("main.onAccountChange", true)

--------------------------------
-- Local function definitions --
--------------------------------

local function onClientThisResourceStart(res)
	--[[local raceRes = getResourceFromName("race")
	if(raceRes and not triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "unbindKey", "k", "down")) then
		setTimer(function()
			local raceRes = getResourceFromName("race")
			if(raceRes) then
				triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "unbindKey", "k", "down")
			end
		end, 1000, 1)
	end]]
	
	loadSettings()
	
	--[[if(not bindKey(g_LocalSettings.suicide_key, "down", suicide)) then
		g_LocalSettings.suicide_key = "k"
		bindKey("k", "down", suicide)
	end]]
	
	triggerServerEvent("main.onPlayerReady", g_ResRoot, g_LocalSettings.locale)
end

local function onClientResourceStart(res)
	--[[if(getResourceName(res) == "race") then
		setTimer(function()
			local raceRes = getResourceFromName("race")
			if(raceRes) then
				triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "unbindKey", "k", "down")
			end
		end, 1000, 1)
	end]]
end

local function onClientThisResourceStop()
	--[[local raceRes = getResourceFromName("race")
	if(raceRes) then
		triggerEvent("onClientCall_race", getResourceRootElement(raceRes), "bindKey", "k", "down", "kill")
	end]]
end

local function onClientPlayerQuit(reason)
	local nick = getPlayerName(source):gsub("#%x%x%x%x%x%x", "")
	
	if(reason == "Kicked") then customMsg(255, 96, 96, "* %s has been kicked from the game.", nick)
	elseif(reason == "Banned") then customMsg(255, 96, 96, "* %s has been banned from the game.", nick)
	elseif(reason == "Quit") then customMsg(255, 96, 96, "* %s has left the game.", nick)
	else customMsg(255, 96, 96, "* %s has left the game [%s].", nick, reason) end
end

local function onAccountChange(accountName, accountId)
	g_UserName = accountName
	g_MyId = accountId
end

local function onClientInit(accountId, settings, isNew, localeId)
	g_MyId = accountId
	g_ServerSettings = settings
	g_LocalSettings.locale = localeId
	triggerEvent("onClientLangChange", g_Root, localeId)
	
	if(isNew) then
		local userPanelKey = getKeyBoundToCommand("UserPanel") or "-"
		local statsPanelKey = getKeyBoundToCommand("StatsPanel") or "-"
		customMsg(255, 96, 96, "Press %s to open User Panel and %s to open Statistics Panel!", userPanelKey, statsPanelKey)
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
addEventHandler("main.onAccountChange", g_ResRoot, onAccountChange)
addInternalEventHandler($(EV_CLIENT_INIT), onClientInit)
addInternalEventHandler($(EV_SET_GRAVITY), setGravity)
