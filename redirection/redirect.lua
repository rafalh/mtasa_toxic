local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ( getThisResource () )
local g_ResName = getResourceName ( getThisResource () )

addEvent ( "onClientRedirectRequest", true )
addEvent ( "onRedirectRequest", true )
addEvent ( "onRedirectorStart", true )

local function onRedirectRequest ()
	redirectPlayer ( client, get ( "ip" ), tonumber ( get ( "port" ) ) )
end

local function strToPattern ( s )
	return s
		:gsub ( "%%", "%%%%" )
		:gsub ( "%^", "%%%^" )
		:gsub ( "%$", "%%%$" )
		:gsub ( "%(", "%%%(" )
		:gsub ( "%)", "%%%)" )
		:gsub ( "%.", "%%%." )
		:gsub ( "%[", "%%%[" )
		:gsub ( "%]", "%%%]" )
		:gsub ( "%*", "%%%*" )
		:gsub ( "%+", "%%%+" )
		:gsub ( "%-", "%%%-" )
		:gsub ( "%?", "%%%?" )
end

local function findPlayer ( str )
	if ( not str ) then
		return false
	end
	
	local player = getPlayerFromName ( str ) -- returns player or false
	if ( player ) then
		return player
	end
	
	str = strToPattern ( str ):upper ()
	for i, player in ipairs ( getElementsByType ( "player" ) ) do
		if ( getPlayerName ( player ):gsub ( "#%x%x%x%x%x%x", "" ):upper ():find ( str ) ) then
			return player
		end
	end
	return false
end

local function cmdRedirect ( source, cmd, name )
	local player = source
	if ( hasObjectPermissionTo ( player, "resource."..g_ResName, false ) ) then
		player = name:len () > 1 and findPlayer ( name )
	end
	if ( player ) then
		redirectPlayer ( player, get ( "ip" ), tonumber ( get ( "port" ) ) )
	end
end

local function onRedirectorStart ()
	if ( get ( "redirect_all" ) == "true" ) then
		triggerClientEvent ( client, "onClientRedirectRequest", g_Root )
	end
end

addEventHandler ( "onRedirectRequest", g_Root, onRedirectRequest )
addEventHandler ( "onRedirectorStart", g_Root, onRedirectorStart )
addCommandHandler ( get ( "redirect_cmd" ) or "redirect", cmdRedirect, false, false )
