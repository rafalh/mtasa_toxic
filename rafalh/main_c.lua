--------------
-- Includes --
--------------

#include "include/internal_events.lua"

-------------------
-- Custom events --
-------------------

addEvent ( "onClientCall_race", true )

--------------------------------
-- Local function definitions --
--------------------------------

local function onClientThisResourceStart ( res )
	local race_res = getResourceFromName ( "race" )
	if ( race_res and not triggerEvent ( "onClientCall_race", getResourceRootElement ( race_res ), "unbindKey", "k", "down" ) ) then
		setTimer ( function ()
			local race_res = getResourceFromName ( "race" )
			if ( race_res ) then
				triggerEvent ( "onClientCall_race", getResourceRootElement ( race_res ), "unbindKey", "k", "down" )
			end
		end, 1000, 1 )
	end
	
	loadSettings ()
	
	if ( not bindKey ( g_ClientSettings.suicide_key, "down", suicide ) ) then
		g_ClientSettings.suicide_key = "k"
		bindKey ( "k", "down", suicide )
	end
	
	triggerServerInternalEvent ( $(EV_RAFALH_START), g_Me )
end

local function onClientResourceStart ( res )
	if ( getResourceName ( res ) == "race" ) then
		setTimer ( function ()
			local race_res = getResourceFromName ( "race" )
			if ( race_res ) then
				triggerEvent ( "onClientCall_race", getResourceRootElement ( race_res ), "unbindKey", "k", "down" )
			end
		end, 1000, 1 )
	end
	
	if ( g_Settings.lang ) then
		triggerEvent ( "onClientLangChange", getResourceRootElement ( res ), g_Settings.lang )
	end
end

local function onClientThisResourceStop ()
	local race_res = getResourceFromName ( "race" )
	if ( race_res ) then
		triggerEvent ( "onClientCall_race", getResourceRootElement ( race_res ), "bindKey", "k", "down", "kill" )
	end
end

local function onClientPlayerQuit ( reason )
	if ( g_WinnerAnim == source ) then
		stopWinnerAnim ()
	end
	
	local nick = getPlayerName ( source ):gsub ( "#%x%x%x%x%x%x", "" )
	
	if ( reason == "Kicked" ) then customMsg ( 255, 96, 96, "* %s has been kicked from the game.", nick )
	elseif ( reason == "Banned" ) then customMsg ( 255, 96, 96, "* %s has been banned from the game.", nick )
	elseif ( reason == "Quit" ) then customMsg ( 255, 96, 96, "* %s has left the game.", nick )
	else customMsg ( 255, 96, 96, "* %s has left the game [%s].", nick, reason ) end
end

local function onClientInit ( accountId, welcomeWnd, settings, isNew )
	g_MyId = accountId
	g_Settings = settings
	
	triggerEvent ( "onClientLangChange", g_Root, settings.lang )
	if(isNew) then
		customMsg ( 255, 96, 96, "Press %s to open User Panel and %s to open Statistics Panel!", g_ClientSettings.user_panel_key, g_ClientSettings.stats_panel_key )
	end
end

local function clearChat ()
	local chat_layout = getChatboxLayout ()
	for i = 1, chat_layout.chat_lines, 1 do
		outputChatBox ( "" )
	end
end

addCommandHandler ( "clearchat", clearChat, false )

--[[local function alpha ( cmd_name, value )
	value = tonumber ( value )
	if ( value and value >= 0 and value <= 255 ) then
		local veh = getPedOccupiedVehicle ( g_Me )
		setElementAlpha ( g_Me, value )
		if ( veh ) then
			setElementAlpha ( veh, value )
		end
	end
end

addCommandHandler ( "alpha", alpha, false )]]

------------
-- Events --
------------

addEventHandler ( "onClientResourceStart", g_Root, onClientResourceStart )
addEventHandler ( "onClientResourceStart", g_ResRoot, onClientThisResourceStart )
addEventHandler ( "onClientResourceStop", g_ResRoot, onClientThisResourceStop )
addEventHandler ( "onClientPlayerQuit", g_Root, onClientPlayerQuit )
addInternalEventHandler ( $(EV_CLIENT_INIT), onClientInit )
addInternalEventHandler ( $(EV_SET_GRAVITY), setGravity )
