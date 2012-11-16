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

local function PmResize ( chat_info )
	local w, h = guiGetSize ( chat_info.wnd, false )
	guiSetSize ( chat_info.chat, w-20, h-85, false )
	guiSetPosition ( chat_info.label, 10, h-60, false )
	guiSetPosition ( chat_info.input, 60, h-60, false )
	guiSetSize ( chat_info.input, w-150, 25, false )
	guiSetPosition ( chat_info.send_btn, w-80, h-60, false )
	guiSetPosition ( chat_info.label2, 10, h-30, false )
	guiSetPosition ( chat_info.bg_btn, w-165, h-30, false )
	guiSetPosition ( chat_info.close_btn, w-70, h-30, false )
end

local function guiMemoAddLine ( memo, str )
	local buf = guiGetText ( memo )
	guiSetText ( memo, buf..str ) --CEGUI samo dodaje na koncu \n
	guiMemoSetCaretIndex ( memo, buf:len () + str:len () )
end

local function PmSend ( chat_info )
	guiBringToFront ( chat_info.input )
	
	local msg = guiGetText ( chat_info.input, "" ):sub ( 1, 128 )
	if (msg == "" ) then return end
	
	guiSetText ( chat_info.input, "" )
	guiMemoAddLine ( chat_info.chat, getPlayerName ( g_Me ):gsub ( "#%x%x%x%x%x%x", "" )..": "..msg )
	
	triggerServerInternalEvent ( $(EV_PLAYER_PM_REQUEST), g_Me, msg, chat_info.player )
end

local function PmChatSize ()
	for player, chat_info in pairs ( g_Chats ) do
		if ( chat_info.wnd == source ) then
			PmResize ( chat_info )
			return
		end
	end
end

local function PmInputAccepted ()
	for player, chat_info in pairs ( g_Chats ) do
		if ( chat_info.input == source ) then
			PmSend ( chat_info )
			return
		end
	end
end

local function PmSendBtnClick ()
	for player, chat_info in pairs ( g_Chats ) do
		if ( chat_info.send_btn == source ) then
			PmSend ( chat_info )
			return
		end
	end
end

local function PmToBackground ( player )
	local chat_info = g_Chats[player]
	guiSetAlpha ( chat_info.wnd, 0.3 )
	guiSetInputEnabled ( false )
	guiSetText ( chat_info.bg_btn, "Restore" )
	chat_info.enabled = false
end

local function PmRestore ( player )
	local chat_info = g_Chats[player]
	guiSetAlpha ( chat_info.wnd, 0.75 )
	guiSetInputEnabled ( true )
	guiSetText ( chat_info.bg_btn, "In background" )
	guiBringToFront ( chat_info.input )
	chat_info.enabled = true
end

local function PmBgBtnClick ()
	for player, chat_info in pairs ( g_Chats ) do
		if ( chat_info.bg_btn == source ) then
			if ( chat_info.enabled ) then
				PmToBackground ( player )
			else
				PmRestore ( player )
			end
			return
		end
	end
end

local function PmCloseBtnClick ()
	for player, chat_info in pairs ( g_Chats ) do
		if ( chat_info.close_btn == source ) then
			guiSetInputEnabled ( false )
			destroyElement ( g_Chats[player].wnd )
			g_Chats[player] = nil
			return
		end
	end
end

local function PmCreateGui ( player )
	local chat_data = {}
	local player_name = getPlayerName ( player ):gsub ( "#%x%x%x%x%x%x", "" )
	chat_data.wnd = guiCreateWindow ( (g_ScreenSize[1]-320)/2, (g_ScreenSize[2]-240)/2, 320, 240, MuiGetMsg ( "Private Chat - %s" ):format ( player_name ), false )
	guiSetAlpha ( chat_data.wnd, 0.75 )
	chat_data.chat = guiCreateMemo ( 10, 20, 300, 155, "", false, chat_data.wnd )
	guiMemoSetReadOnly ( chat_data.chat, true )
	chat_data.label = guiCreateLabel ( 10, 180, 50, 15, "Say:", false, chat_data.wnd )
	chat_data.input = guiCreateEdit ( 60, 180, 170, 25, "", false, chat_data.wnd )
	guiSetProperty ( chat_data.input, "MaxTextLength", "128" )
	chat_data.send_btn = guiCreateButton ( 240, 180, 70, 25, "Send", false, chat_data.wnd )
	chat_data.label2 = guiCreateLabel ( 10, 210, 140, 15, MuiGetMsg ( "* %s has left the game." ):format ( "Player" ), false, chat_data.wnd )
	guiSetAlpha ( chat_data.label2, 0 )
	guiLabelSetColor ( chat_data.label2, 255, 0, 0 )
	
	chat_data.bg_btn = guiCreateButton ( 155, 210, 85, 25, "In background", false, chat_data.wnd )
	chat_data.close_btn = guiCreateButton ( 250, 210, 60, 25, "Close", false, chat_data.wnd )
	chat_data.player = player
	chat_data.enabled = true
	g_Chats[player] = chat_data
	--PmResize ( chat_data )
	
	addEventHandler ( "onClientGUISize", chat_data.wnd, PmChatSize, false )
	addEventHandler ( "onClientGUIAccepted", chat_data.input, PmInputAccepted, false )
	addEventHandler ( "onClientGUIClick", chat_data.send_btn, PmSendBtnClick, false )
	addEventHandler ( "onClientGUIClick", chat_data.bg_btn, PmBgBtnClick, false )
	addEventHandler ( "onClientGUIClick", chat_data.close_btn, PmCloseBtnClick, false )
end

local function PmCmdHandler ( command, nick, msg )
	local player = findPlayer ( nick )
	
	if ( not player ) then
		customMsg ( 255, 96, 96, "PM: Usage: %s", command.." <nick> [<message>]" )
		return
	end
	
	if ( msg ) then
		msg = msg:sub ( 1, 128 )
		if ( g_Chats[player] ) then
			guiMemoAddLine ( g_Chats[player].chat, getPlayerName ( g_Me ):gsub ( "#%x%x%x%x%x%x", "" )..": "..msg )
		end
		
		triggerServerInternalEvent ( $(EV_PLAYER_PM_REQUEST), g_Me, msg, player )
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
		guiMemoAddLine ( g_Chats[source].chat, getPlayerName ( source ):gsub ( "#%x%x%x%x%x%x", "" )..": "..msg )
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
