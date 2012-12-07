--------------
-- Includes --
--------------

#include "include/internal_events.lua"
#include "../include/serv_verification.lua"

---------------------
-- Local variables --
---------------------

local g_Chats = {}
local g_Verified = false

--------------------------------
-- Local function definitions --
--------------------------------

local function PmResize ( chatInfo )
	local w, h = guiGetSize ( chatInfo.wnd, false )
	guiSetSize ( chatInfo.chat, w-20, h-85, false )
	guiSetPosition ( chatInfo.label, 10, h-60, false )
	guiSetPosition ( chatInfo.input, 60, h-60, false )
	guiSetSize ( chatInfo.input, w-150, 25, false )
	guiSetPosition ( chatInfo.send_btn, w-80, h-60, false )
	guiSetPosition ( chatInfo.label2, 10, h-30, false )
	guiSetPosition ( chatInfo.bg_btn, w-165, h-30, false )
	guiSetPosition ( chatInfo.close_btn, w-70, h-30, false )
end

local function guiMemoAddLine ( memo, str )
	local buf = guiGetText ( memo )
	guiSetText ( memo, buf..str ) --CEGUI samo dodaje na koncu \n
	guiMemoSetCaretIndex ( memo, buf:len () + str:len () )
end

local function PmSend ( chatInfo )
	guiBringToFront ( chatInfo.input )
	
	local msg = guiGetText ( chatInfo.input, "" ):sub ( 1, 128 )
	if (msg == "" ) then return end
	
	guiSetText ( chatInfo.input, "" )
	guiMemoAddLine ( chatInfo.chat, getPlayerName ( g_Me ):gsub ( "#%x%x%x%x%x%x", "" )..": "..msg )
	
	triggerServerInternalEvent ( $(EV_PLAYER_PM_REQUEST), g_Me, msg, chatInfo.player )
end

local function PmChatSize ()
	for player, chatInfo in pairs ( g_Chats ) do
		if ( chatInfo.wnd == source ) then
			PmResize ( chatInfo )
			return
		end
	end
end

local function PmInputAccepted ()
	for player, chatInfo in pairs ( g_Chats ) do
		if ( chatInfo.input == source ) then
			PmSend ( chatInfo )
			return
		end
	end
end

local function PmSendBtnClick ()
	for player, chatInfo in pairs ( g_Chats ) do
		if ( chatInfo.send_btn == source ) then
			PmSend ( chatInfo )
			return
		end
	end
end

local function PmToBackground ( player )
	local chatInfo = g_Chats[player]
	guiSetAlpha ( chatInfo.wnd, 0.3 )
	guiSetInputEnabled ( false )
	guiSetText ( chatInfo.bg_btn, "Restore" )
	chatInfo.enabled = false
end

local function PmRestore ( player )
	local chatInfo = g_Chats[player]
	guiSetAlpha ( chatInfo.wnd, 0.75 )
	guiSetInputEnabled ( true )
	guiSetText ( chatInfo.bg_btn, "In background" )
	guiBringToFront ( chatInfo.input )
	chatInfo.enabled = true
end

local function PmBgBtnClick ()
	for player, chatInfo in pairs ( g_Chats ) do
		if ( chatInfo.bg_btn == source ) then
			if ( chatInfo.enabled ) then
				PmToBackground ( player )
			else
				PmRestore ( player )
			end
			return
		end
	end
end

local function PmCloseBtnClick ()
	for player, chatInfo in pairs(g_Chats) do
		if (chatInfo.close_btn == source) then
			if(chatInfo.enabled) then
				guiSetInputEnabled(false)
			end
			destroyElement(chatInfo.wnd)
			g_Chats[player] = nil
			return
		end
	end
end

local function PmCreateGui ( player )
	local chatInfo = {}
	local player_name = getPlayerName ( player ):gsub ( "#%x%x%x%x%x%x", "" )
	chatInfo.wnd = guiCreateWindow ( (g_ScreenSize[1]-320)/2, (g_ScreenSize[2]-240)/2, 320, 240, MuiGetMsg ( "Private Chat - %s" ):format ( player_name ), false )
	guiSetAlpha ( chatInfo.wnd, 0.75 )
	chatInfo.chat = guiCreateMemo ( 10, 20, 300, 155, "", false, chatInfo.wnd )
	guiMemoSetReadOnly ( chatInfo.chat, true )
	chatInfo.label = guiCreateLabel ( 10, 180, 50, 15, "Say:", false, chatInfo.wnd )
	chatInfo.input = guiCreateEdit ( 60, 180, 170, 25, "", false, chatInfo.wnd )
	guiSetProperty ( chatInfo.input, "MaxTextLength", "128" )
	chatInfo.send_btn = guiCreateButton ( 240, 180, 70, 25, "Send", false, chatInfo.wnd )
	chatInfo.label2 = guiCreateLabel ( 10, 210, 140, 15, MuiGetMsg ( "* %s has left the game." ):format ( "Player" ), false, chatInfo.wnd )
	guiSetAlpha ( chatInfo.label2, 0 )
	guiLabelSetColor ( chatInfo.label2, 255, 0, 0 )
	
	chatInfo.bg_btn = guiCreateButton ( 155, 210, 85, 25, "In background", false, chatInfo.wnd )
	chatInfo.close_btn = guiCreateButton ( 250, 210, 60, 25, "Close", false, chatInfo.wnd )
	chatInfo.player = player
	chatInfo.enabled = true
	g_Chats[player] = chatInfo
	--PmResize ( chatInfo )
	
	addEventHandler ( "onClientGUISize", chatInfo.wnd, PmChatSize, false )
	addEventHandler ( "onClientGUIAccepted", chatInfo.input, PmInputAccepted, false )
	addEventHandler ( "onClientGUIClick", chatInfo.send_btn, PmSendBtnClick, false )
	addEventHandler ( "onClientGUIClick", chatInfo.bg_btn, PmBgBtnClick, false )
	addEventHandler ( "onClientGUIClick", chatInfo.close_btn, PmCloseBtnClick, false )
end

local function PmCmdHandler ( command, nick, ... )
	local player = findPlayer ( nick )
	
	if ( not player ) then
		customMsg ( 255, 96, 96, "PM: Usage: %s", command.." <nick> [<message>]" )
		return
	end
	
	local msg = table.concat({...}, " ")
	if(msg ~= "") then
		msg = msg:sub ( 1, 128 )
		if ( g_Chats[player] ) then
			local myName = getPlayerName ( g_Me ):gsub ( "#%x%x%x%x%x%x", "" )
			guiMemoAddLine ( g_Chats[player].chat, myName..": "..msg )
		end
		
		triggerServerInternalEvent ( $(EV_PLAYER_PM_REQUEST), g_Me, msg, player )
		local playerName = getPlayerName ( player ):gsub ( "#%x%x%x%x%x%x", "" )
		customMsg ( 255, 96, 96, "You have sent PM to %s: %s", playerName, msg )
	elseif ( g_Chats[player] ) then
		PmRestore ( player )
	else
		PmCreateGui ( player )
		guiBringToFront ( g_Chats[player].input )
		guiSetInputEnabled ( true )
	end
end

local function onClientPlayerPrivateMessage ( msg )
	if ( g_Chats[source] ) then
		local playerName = getPlayerName ( source ):gsub ( "#%x%x%x%x%x%x", "" )
		guiMemoAddLine ( g_Chats[source].chat, playerName..": "..msg )
	end
end

local function onClientPlayerQuit ()
	if ( g_Chats[source] ) then
		g_Chats[#g_Chats + 1] = g_Chats[source]
		g_Chats[source] = nil
		guiSetEnabled ( g_Chats[#g_Chats].send_btn, false )
		removeEventHandler ( "onClientGUIAccepted", g_Chats[#g_Chats].input, PmInputAccepted )
		guiSetAlpha ( g_Chats[#g_Chats].label2, 255 )
	end
end

--------------
-- Commands --
--------------

#VERIFY_SERVER_BEGIN ( "593C2070A55147B063D423AFAC7003D6" )
	addCommandHandler ( "pm", PmCmdHandler, false )
	addInternalEventHandler ( $(EV_CLIENT_PLAYER_PM), onClientPlayerPrivateMessage )
	addEventHandler ( "onClientPlayerQuit", g_Root, onClientPlayerQuit )
	g_Verified = true
#VERIFY_SERVER_END ()
