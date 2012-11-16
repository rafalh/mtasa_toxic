local function AvpTimerProc ()
	local m = SmGetUInt ( "arit_avg_players_m", 0 )
	local avg = SmGetNum ( "avg_players", 0 )
	
	if ( m < 60*24*7 ) then -- during first week use aritmetic average
		SmSet ( "avg_players", ( avg*m + g_PlayersCount )/( m + 1 ) )
		SmSet ( "arit_avg_players_m", m + 1 )
	else
		SmSet ( "avg_players", avg*0.99993 + g_PlayersCount*0.00007 ) -- last week has weight of 50%; 0.5^(1/60/24/7)
	end
end

local function AvpInit ()
	setTimer ( AvpTimerProc, 60000, 0 )
end

addEventHandler ( "onResourceStart", g_ResRoot, AvpInit )
