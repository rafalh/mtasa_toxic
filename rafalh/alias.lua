local function AlAddPlayerAlias ( player, name )
	name = name:gsub ( "#%x%x%x%x%x%x", "" )
	local pdata = g_Players[player]
	
	local rows = DbQuery ( "SELECT player FROM rafalh_names WHERE player=? AND name=? LIMIT 1", pdata.id, name )
	if ( not rows or not rows[1] ) then
		DbQuery ( "INSERT INTO rafalh_names (player, name) VALUES (?, ?)", pdata.id, name )
	end
end

local function AlInit ()
	for player, pdata in pairs ( g_Players ) do
		AlAddPlayerAlias ( player, getPlayerName ( player ) )
	end
end

local function AlOnPlayerChangeNick ( oldNick, newNick )
	if ( wasEventCancelled () ) then return end
	
	if ( g_Players[source] ) then
		AlAddPlayerAlias ( source, newNick )
	end
end

local function AlOnPlayerJoin ()
	AlAddPlayerAlias ( source, getPlayerName ( source ) )
end

addEventHandler ( "onResourceStart", g_ResRoot, AlInit )
addEventHandler ( "onPlayerJoin", g_Root, AlOnPlayerJoin )
addEventHandler ( "onPlayerChangeNick", g_Root, AlOnPlayerChangeNick )
