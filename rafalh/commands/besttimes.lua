local function CmdBestTime (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local room = g_Players[player].room
	local map_id = getCurrentMap(room):getId()
	local rows = DbQuery ("SELECT time FROM rafalh_besttimes WHERE player=? AND map=? LIMIT 1", g_Players[player].id, map_id)
	
	if (rows and rows[1]) then
		scriptMsg ("%s's personal best time: %s.", getPlayerName (player), formatTimePeriod (rows[1].time / 1000))
	else
		scriptMsg ("%s's personal best time: %s.", getPlayerName (player), "none")
	end
end

CmdRegister ("besttime", CmdBestTime, false, "Shows player best time on current map")

function BtPrintTopTimes ()
	local room = g_Players[source].room
	local map_id = getCurrentMap(room):getId()
	local rows = DbQuery ("SELECT player, time FROM rafalh_besttimes WHERE map=? ORDER BY time LIMIT 3", map_id)
	
	if (rows and #rows > 0) then
		scriptMsg ("Top Times:")
		for i, data in ipairs (rows) do
			local data2 = DbQuery ("SELECT name FROM rafalh_players WHERE player=? LIMIT 1", data.player)
			scriptMsg ("%u. %s - %s", i, data2[1].name, formatTimePeriod (data.time/1000))
		end
	else
		scriptMsg ("No top times saved!")
	end
end
