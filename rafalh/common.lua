----------------------
-- Global variables --
----------------------

g_Root = getRootElement ()
g_ResRoot = getResourceRootElement ()
g_Players = {}
g_PlayersCount = 0
g_ScriptMsgState = { recipients = { g_Root }, prefix = "", color = false }
g_InternalEventHandlers = {}
g_OldVehicleWeapons = nil
g_Countries = {}
g_IsoLangs = {}
g_MapTypes = {}
g_BannedNames = {}
g_CustomRights = {}
g_IdToPlayer = {}

---------------------
-- Local variables --
---------------------

local g_ThisRes = getThisResource ()
local g_ThisResName = getResourceName ( g_ThisRes )

-------------------
-- Custom events --
-------------------

addEvent ( "onEvent_"..g_ThisResName, true )

--------------------------------
-- Local function definitions --
--------------------------------

local function onEventHandler ( event, ... )
	--outputChatBox("'"..getResourceName ( sourceResource ).."' "..tostring(event))
	if ( g_InternalEventHandlers[event or false] and ( sourceResource == g_ThisRes or getResourceName ( sourceResource ):sub ( 1, 6 ) == "rafalh" ) ) then
		for _, handler in ipairs ( g_InternalEventHandlers[event] ) do
			-- Note: unpack must be last arg
			handler ( unpack ( { ... } ) )
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function divChatStr ( str )
	local tbl = {}
	
	while ( str:len () > 0 ) do
		local t = str:sub ( 1, 128 ):reverse ():find ( " " )
		local part = str:sub ( 1, ( t and ( 129 - t ) ) or 128 )
		table.insert ( tbl, part )
		str = str:sub ( part:len () + 1 )
	end
	
	return tbl
end

function privMsg ( player, fmt, ... )
	local msg = "PM: "..MuiGetMsg ( fmt, player ):format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
	local is_console = getElementType ( player ) == "console"
	
	if ( is_console ) then
		outputServerLog ( msg )
	else
		local parts = divChatStr ( msg )
		
		for i, part in ipairs ( parts ) do
			outputChatBox ( part, player, 255, 96, 96, false )
		end
	end
end

function scriptMsg ( fmt, ... )
	if ( g_ScriptMsgState.recipients[1] == g_Root ) then -- everybody is a recipient
		local part = g_ScriptMsgState.prefix..fmt:format ( ... ):gsub ( "#%x%x%x%x%x%x", "" ):sub ( 1, 128 )
		
		--outputServerLog ( part )
		
		local rafalh_webchat_res = getResourceFromName ( "rafalh_webchat" )
		if ( rafalh_webchat_res and getResourceState ( rafalh_webchat_res ) == "running" ) then
			call ( rafalh_webchat_res, "addChatStr", "#ffc46e"..part )
		end
	end
	
	local recipients = {}
	for i, element in ipairs ( g_ScriptMsgState.recipients ) do
		for i, player in ipairs ( getElementsByType ( "player", element ) ) do
			table.insert ( recipients, player )
		end
		for i, console in ipairs ( getElementsByType ( "console", element ) ) do
			table.insert ( recipients, console )
		end
	end
	
	local r, g, b = 255, 196, 128
	if ( g_ScriptMsgState.color ) then
		r, g, b = getColorFromString ( g_ScriptMsgState.color )
	end
	
	for i, player in ipairs ( recipients ) do
		local msg = g_ScriptMsgState.prefix..MuiGetMsg ( fmt, player ):format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
		local parts = divChatStr ( msg )
		local is_console = getElementType ( player ) == "console"
		
		for i, part in ipairs ( parts ) do
			if ( is_console ) then
				outputServerLog ( part )
			else
				outputChatBox ( part, player, r, g, b, false )
			end
		end
	end
end

function customMsg ( r, g, b, fmt, ... )
	local msg = fmt:format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
	outputServerLog ( msg )
	local rafalh_webchat_res = getResourceFromName ( "rafalh_webchat" )
	if ( rafalh_webchat_res and getResourceState ( rafalh_webchat_res ) == "running" ) then
		call ( rafalh_webchat_res, "addChatStr", ( "#%02x%02x%02x" ):format ( r, g, b )..msg )
	end
	
	for i, player in ipairs ( getElementsByType ( "player" ) ) do
		local msg = MuiGetMsg ( fmt, player ):format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
		outputChatBox ( msg, player, r, g, b, false )
	end
end

function outputMsg(visibleTo, color, fmt, ...)
	if(not color) then
		color = "#ffc46e"
	end
	
	local msg = fmt:format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
	if(visibleTo == g_Root or getElementType(visibleTo) == "game-room") then
		outputServerLog ( msg )
		
		local rafalh_webchat_res = getResourceFromName ( "rafalh_webchat" )
		if ( rafalh_webchat_res and getResourceState ( rafalh_webchat_res ) == "running" ) then
			call ( rafalh_webchat_res, "addChatStr", color..msg )
		end
	end
	
	local r, g, b = getColorFromString(color)
	for i, player in ipairs(getElementsByType("player", visibleTo)) do
		local msg = MuiGetMsg(fmt, player):format (...):gsub("#%x%x%x%x%x%x", "")
		outputChatBox(msg, player, r, g, b, false)
	end
end

function findPlayer ( str )
	if ( not str ) then
		return false
	end
	
	local player = getPlayerFromName ( str ) -- returns player or false
	if ( g_Players[player] ) then
		return player
	end
	
	str = str:lower ()
	for player, pdata in pairs ( g_Players ) do
		if ( not pdata.is_console ) then
			local name = getPlayerName ( player ):gsub ( "#%x%x%x%x%x%x", "" ):lower ()
			if ( name:find ( str, 1, true ) ) then
				return player
			end
		end
	end
	return false
end

function strGradient ( str, r1, g1, b1, r2, g2, b2 )
	local n = math.max ( math.abs ( r1 - r2 )/25.5, math.abs ( b1 - b2 )/25.5, math.abs ( b1 - b2 )/25.5, 2 ) -- max 10 codes, min 2
	local part_len = math.ceil ( str:len ()/n )
	local buf = ""
	for i = 0, math.ceil ( n ) - 1, 1 do
		local a = i/( n - 1 )
		buf = buf..( "#%02X%02X%02X" ):format ( r1*( 1 - a ) + r2*a, g1*( 1 - a ) + g2*a, b1*( 1 - a ) + b2*a )..str:sub ( 1 + i*part_len, ( i + 1 )*part_len )
	end
	return buf
end

function addScreenMsg ( text, player, ms, r, g, b )
	assert ( not ms or ms > 50 )
	
	local players = getElementsByType ( "player", player )
	local textitem
	
	for i, player in ipairs ( players ) do
		local pdata = g_Players[player]
		
		if ( not pdata.display ) then
			pdata.display = textCreateDisplay ()
			textDisplayAddObserver ( pdata.display, player )
			pdata.scrMsgs = {}
		end
		local msg = MuiGetMsg ( text, player )
		textitem = textCreateTextItem ( msg, 0.5, 0.4 + #pdata.scrMsgs * 0.05, "medium", r or 255, g or 0, b or 0, 255, 3, "center" )
		table.insert ( pdata.scrMsgs, textitem )
		textDisplayAddText ( pdata.display, textitem )
		
		if ( ms ) then
			addPlayerTimer ( removeScreenMsg, ms, 1, player, textitem )
		end
	end
	
	return textitem
end

function removeScreenMsg ( msgItem, player )
	local index = false
	for i, textItem in ipairs ( g_Players[player].scrMsgs ) do
		if ( index ) then -- msgs under textItem
			local x, y = textItemGetPosition ( textItem )
			textItemSetPosition ( textItem, x, y - 0.05 )
		elseif ( textItem == msgItem ) then
			index = i
		end
	end
	assert ( index )
	table.remove ( g_Players[player].scrMsgs, index )
	textDestroyTextItem ( msgItem )
end

local function setPlayerVoiceMuted ( player, muted )
	local voice_res = getResourceFromName ( "voice" )
	if ( voice_res and getResourceState ( voice_res ) == "running" ) then
		return call ( voice_res, "setPlayerVoiceMuted", player, muted )
	end
	return false
end

local function unmuteTimerProc ( player )
	if ( isPlayerMuted ( player ) ) then
		setPlayerMuted ( player, false )
		customMsg ( 0, 255, 0, "%s has been unmuted by Script!", getPlayerName ( player ) )
	end
	setPlayerVoiceMuted ( player, false )
end

function mutePlayer ( player, sec, admin, quiet )
	setPlayerMuted ( player, true )
	setPlayerVoiceMuted ( player, true )
	
	if ( not quiet ) then
		if ( admin ) then
			customMsg ( 255, 0, 0, "%s has been muted by %s!", getPlayerName ( player ), getPlayerName ( admin ) )
		else
			customMsg ( 255, 0, 0, "%s has been muted by Script!", getPlayerName ( player ) )
		end
	end
	
	sec = touint ( sec, 0 )
	if ( sec > 0 ) then
		setPlayerTimer ( unmuteTimerProc, sec * 1000, 1, player )
	end
end

function addInternalEventHandler ( eventtype, handler )
	assert ( eventtype and handler )
	if ( not g_InternalEventHandlers[eventtype] ) then
		g_InternalEventHandlers[eventtype] = {}
	end
	table.insert ( g_InternalEventHandlers[eventtype], handler )
end

function triggerClientInternalEvent ( player, eventtype, source, ... )
	assert (eventtype and isElement(source) and isElement(player))
	
	local players = getElementsByType("player", player)
	for i, player in ipairs(players) do
		local pdata = g_Players[player]
		if(pdata and pdata.sync) then
			triggerClientEvent(player, "onEvent_"..g_ThisResName, source, eventtype, ...)
		end
	end
end

------------
-- Events --
------------

addEventHandler ( "onEvent_"..g_ThisResName, g_Root, onEventHandler )
