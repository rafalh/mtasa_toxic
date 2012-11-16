local function IvTimerProc ( player )
	-- give award for player who invited
	local pdata = g_Players[player]
	local rows = DbQuery ( "SELECT invitedby FROM rafalh_players WHERE player=? LIMIT 1", pdata.id )
	local invitedby = rows[1].invitedby
	if ( invitedby > 0 ) then
		DbQuery ( "UPDATE rafalh_players SET invitedby=0 WHERE player=?", pdata.id )
		StSet ( invitedby, "cash", StGet ( invitedby, "cash" ) + 1000000 )
		
		local invitedby_player = g_IdToPlayer[invitedby]
		if ( invitedby_player ) then
			privMsg ( invitedby_player, "You get %s for inviting %s!", formatMoney ( 1000000 ), getPlayerName ( player ) )
		end
	end
end

local function IvNewPlayer ( player )
	local playtime = StGet ( player, "time_here" )
	
	if ( playtime < 10*3600 ) then
		setPlayerTimer ( IvTimerProc, ( 10*3600 - playtime ) * 1000, 1, player )
	end
end

local function IvInit ()
	for player, pdata in pairs ( g_Players ) do
		IvNewPlayer ( player )
	end
end

local function IvOnPlayerJoin ()
	IvNewPlayer ( source )
end

addEventHandler ( "onResourceStart", g_ResRoot, IvInit )
addEventHandler ( "onPlayerJoin", g_Root, IvOnPlayerJoin )
