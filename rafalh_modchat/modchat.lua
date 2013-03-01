---------------------
-- Local variables --
---------------------

local g_Root = getRootElement ()
local g_SyncedPlayers = {}

-------------------
-- Custom events --
-------------------

addEvent ( "onClientSetMod", true )
addEvent ( "onModChatStart", true )
addEvent ( "onModChat", true )

--------------------------------
-- Local function definitions --
--------------------------------

local function McSay ( player, msg )
	msg = tostring ( msg )
	if ( msg == "" or not hasObjectPermissionTo ( player, "resource.rafalh_modchat", false ) ) then return end
	
	if ( isPlayerMuted ( player ) ) then
		outputChatBox ( "modchat: You are muted!", player, 255, 128, 0 )
		return
	end
	
	msg = utfSub ( msg, 1, 128 )
	
	local recipients = {}
	for i, player in ipairs ( getElementsByType ( "player" ) ) do
		if ( hasObjectPermissionTo ( player, "resource.rafalh_modchat", false ) ) then
			table.insert ( recipients, player )
		end
	end
	
	if ( utfSub ( msg, 1, 1 ) ~= "/" ) then
		local str = "(MOD) "..getPlayerName ( player )..": #EBDDB2"..msg
		local r, g, b = getPlayerNametagColor ( player )
		for i, player in ipairs(recipients) do
			outputChatBox ( str, player, r, g, b, true )
		end
		outputServerLog ( "MODSAY: "..( getPlayerName ( player )..": "..msg ) )
	end
	
	local rafalh_res = getResourceFromName ( "rafalh" )
	if ( rafalh_res and getResourceState ( rafalh_res ) == "running" ) then
		call ( rafalh_res, "parseCommand", msg, player, recipients, "(MOD) " )
	end
end

local function McPlayerSay ( msg )
	McSay ( client, msg )
end

local function McPlayerInit ()
	g_SyncedPlayers[client] = true
	if ( hasObjectPermissionTo ( client, "resource.rafalh_modchat", false ) ) then
		triggerClientEvent ( client, "onClientSetMod", g_Root )
	end
end

local function McPlayerLogin ()
	if ( g_SyncedPlayers[source] and hasObjectPermissionTo ( source, "resource.rafalh_modchat", false ) ) then
		triggerClientEvent ( source, "onClientSetMod", g_Root )
	end
end

local function McPlayerQuit ()
	g_SyncedPlayers[source] = nil
end

local function McConsole ( msg )
	if ( msg:sub ( 1, 6 + 1 ) == "modsay " ) then
		McSay ( source, msg:sub ( 1 + 6 + 1 ) )
	end
end

------------
-- Events --
------------

addEventHandler ( "onModChat", g_Root, McPlayerSay )
addEventHandler ( "onModChatStart", g_Root, McPlayerInit )
addEventHandler ( "onPlayerLogin", g_Root, McPlayerLogin )
addEventHandler ( "onPlayerQuit", g_Root, McPlayerQuit )
addEventHandler ( "onConsole", g_Root, McConsole )
