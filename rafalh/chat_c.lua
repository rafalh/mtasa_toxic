--------------
-- Includes --
--------------

#include "include/internal_events.lua"

addEvent ( "onPlayerChatting", true )
addEvent ( "onClientPlayerChatting", true )

----------------------
-- Global variables --
----------------------

local g_ChatMsgs = {}
local g_ChattingPlayers = {}
local g_Chatting = false

--------------------------------
-- Local function definitions --
--------------------------------

local function init ()
	setTimer ( function ()
		local t = getTickCount ()
		
		for player, msgs in pairs ( g_ChatMsgs ) do
			local i = 1
			while ( i <= #msgs ) do
				while ( i <= #msgs and t - msgs[i][1] > 5000 ) do
					table.remove ( msgs, i )
				end
				i = i + 1
			end
		end
		
		if ( g_Chatting ~= isChatBoxInputActive () ) then
			g_Chatting = not g_Chatting
			triggerServerEvent ( "onPlayerChatting", g_Me, g_Chatting )
		end
	end, 250, 0 )
end

local function onRender ()
	local cx, cy, cz = getCameraMatrix ()
	
	for player, msgs in pairs ( g_ChatMsgs ) do
		local x, y, z = getElementPosition ( player )
		local screen_x, screen_y = getScreenFromWorldPosition ( x, y, z + 1 )
		local dist = getDistanceBetweenPoints3D ( x, y, z, cx, cy, cz )
		
		if ( screen_x and dist < 50 and not isPlayerDead ( player ) and isLineOfSightClear ( x, y, z, cx, cy, cz, true, false, true, true ) ) then
			local scale = 5 / math.max ( math.sqrt ( dist ), 0.1 )
			local g_FontH = dxGetFontHeight ( scale )
			screen_y = screen_y - #msgs * ( g_FontH + 5 )
			
			for i, msg in ipairs ( msgs ) do
				dxDrawText ( msg[2], screen_x + 2, screen_y + i * ( g_FontH + scale ) + 2, screen_x + 2, 0, tocolor ( 0, 0, 0 ), scale, "default", "center" )
				dxDrawText ( msg[2], screen_x, screen_y + i * ( g_FontH + scale ), screen_x, 0, tocolor ( 255, 255, 255 ), scale, "default", "center" )
			end
		end
	end
	
	for player, v in pairs ( g_ChattingPlayers ) do
		local x, y, z = getElementPosition ( player )
		local screen_x, screen_y = getScreenFromWorldPosition ( x, y, z + 1 )
		local dist = getDistanceBetweenPoints3D ( x, y, z, cx, cy, cz )
		
		if ( screen_x and dist < 50 and not isPlayerDead ( player ) and isLineOfSightClear ( x, y, z, cx, cy, cz, true, false, true, true ) ) then
			local size = 200 / math.max ( math.sqrt ( dist ), 0.1 )
			
			dxDrawImage ( screen_x - size / 2, screen_y - size / 2, size, size, "img/chat.png" )
		end
	end
end

local function onPlayerChat ( message )
	if ( isElementStreamedIn ( source ) ) then
		if ( not g_ChatMsgs[source] ) then
			g_ChatMsgs[source] = {}
		end
		table.insert ( g_ChatMsgs[source], { getTickCount (), message } )
	end
end

local function onPlayerChatting ( chatting )
	g_ChattingPlayers[source] = chatting and true or nil
end

local function onPlayerQuit ()
	g_ChatMsgs[source] = nil
	g_ChattingPlayers[source] = nil
end

------------
-- Events --
------------

addInternalEventHandler ( $(EV_CLIENT_PLAYER_CHAT), onPlayerChat )
addEventHandler ( "onClientPlayerChatting", g_Root, onPlayerChatting )
addEventHandler ( "onClientRender", g_Root, onRender )
addEventHandler ( "onClientResourceStart", g_ResRoot, init )
addEventHandler ( "onClientPlayerQuit", g_Root, onPlayerQuit )

