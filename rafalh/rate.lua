local g_Poll = false

addEvent ( "onPollStarting" )
addEvent ( "onPlayerRate", true )
addEvent ( "onClientSetRateGuiVisibleReq", true )

function RtPlayerRate ( rate )
	local room = g_Players[source].room
	local map = getCurrentMap(room)
	rate = touint ( rate, 0 )
	if ( rate < 1 or rate > 10 or not map ) then
		return false
	end
	
	local map_id = map:getId()
	local map_rows = DbQuery ( "SELECT rates, rates_count FROM rafalh_maps WHERE map=? LIMIT 1", map_id )
	
	local rows = DbQuery ( "SELECT rate FROM rafalh_rates WHERE player=? AND map=? LIMIT 1", g_Players[source].id, map_id )
	if ( not rows or not rows[1] or SmGetBool ( "allow_rate_change" ) ) then
		if ( rows and rows[1] and map_rows[1].rates_count > 0 ) then
			map_rows[1].rates = map_rows[1].rates - rows[1].rate
		else
			map_rows[1].rates_count = map_rows[1].rates_count + 1
		end
		map_rows[1].rates = map_rows[1].rates + rate
		
		DbQuery ( "DELETE FROM rafalh_rates WHERE player=? AND map=?", g_Players[source].id, map_id )
		DbQuery ( "INSERT INTO rafalh_rates (player, map, rate) VALUES(?, ?, ?)", g_Players[source].id, map_id, rate )
		DbQuery ( "UPDATE rafalh_maps SET rates=?, rates_count=? WHERE map=?", map_rows[1].rates, map_rows[1].rates_count, map_id )
		
		privMsg ( source, "Rate added! Current average rating: %.2f", map_rows[1].rates / map_rows[1].rates_count )
		
		BtSendMapInfo ( false )
	else
		privMsg ( source, "You rated this map before: %u!", rows[1].rate )
	end
end

local function RtShowGuiForPlayer ( player, map_id )
	local rows = DbQuery ( "SELECT rate FROM rafalh_rates WHERE player=? AND map=? LIMIT 1", g_Players[player].id, map_id )
	if ( not rows or not rows[1] ) then
		triggerClientEvent ( player, "onClientSetRateGuiVisibleReq", g_Root, true )
	end
end

local function RtTimerProc (room)
	local map = getCurrentMap(room)
	if ( map and not g_Poll ) then
		local map_id = map:getId()
		for player, pdata in pairs ( g_Players ) do
			RtShowGuiForPlayer ( player, map_id )
		end
	end
end

local function RtMapStart ()
	setMapTimer(RtTimerProc, 60 * 1000, 1, g_Root) -- FIXME
	g_Poll = false
end

local function RtPoolStarting ()
	--outputDebugString ( "RtPoolStarting", 3 )
	triggerClientEvent ( g_Root, "onClientSetRateGuiVisibleReq", g_Root, false )
	g_Poll = true
end

addEventHandler ( "onGamemodeMapStart", g_Root, RtMapStart ) -- FIXME
addEventHandler ( "onPlayerRate", g_Root, RtPlayerRate )
addEventHandler( "onPollStarting", g_Root, RtPoolStarting )
