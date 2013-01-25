function NlCheckPlayer ( player, name, change )
	name = name:lower ():gsub ( "#%x%x%x%x%x%x", "" )
	
	local rows = DbQuery ( "SELECT locked_nick, name FROM rafalh_players WHERE player=? LIMIT 1", g_Players[player].id )
	
	if ( rows[1].locked_nick == 1 and name ~= rows[1].name ) then
		privMsg ( player, "Your name is locked!" )
		if ( change ) then
			setPlayerName ( player, rows[1].name )
		end
		return true
	end
	
	return false
end

--[[local function NlInit ()
	for player, pdata in pairs ( g_Players ) do
		NlCheckPlayer ( player, getPlayerName ( player ), true )
	end
end

local function NlOnPlayerJoin ()
	if ( wasEventCancelled () ) then return end
	outputChatBox ( "NlOnPlayerJoin" )
	NlCheckPlayer ( source, getPlayerName ( source ), true )
end

local function NlOnPlayerChangeNick ( oldNick, newNick )
	if ( wasEventCancelled () ) then return end
	
	if ( NlCheckPlayer ( source, newNick ) ) then
		cancelEvent ()
	end
end

addEventHandler ( "onResourceStart", g_ResRoot, NlInit )
addEventHandler ( "onPlayerJoin", g_Root, NlOnPlayerJoin )
addEventHandler ( "onPlayerChangeNick", g_Root, NlOnPlayerChangeNick )]]
