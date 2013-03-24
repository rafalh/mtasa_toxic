local function CmdBestTime (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local pdata = Player.fromEl(player)
	local map_id = getCurrentMap(pdata.room):getId()
	local rows = pdata.id and DbQuery("SELECT time FROM rafalh_besttimes WHERE player=? AND map=? LIMIT 1", pdata.id, map_id)
	
	if(rows and rows[1]) then
		scriptMsg("%s's personal best time: %s.", getPlayerName (player), formatTimePeriod (rows[1].time / 1000))
	else
		scriptMsg("%s's personal best time: %s.", getPlayerName (player), "none")
	end
end

CmdRegister ("besttime", CmdBestTime, false, "Shows player best time on current map")

function BtPrintTopTimes ()
	local room = Player.fromEl(source).room
	local map_id = getCurrentMap(room):getId()
	local rows = DbQuery("SELECT bt.player, bt.time, p.name FROM rafalh_besttimes bt, rafalh_players p WHERE map=? AND bt.player=p.player ORDER BY time LIMIT 3", map_id)
	
	if (rows and #rows > 0) then
		scriptMsg("Top Times:")
		for i, data in ipairs(rows) do
			scriptMsg("%u. %s - %s", i, data.name, formatTimePeriod(data.time/1000))
		end
	else
		scriptMsg("No top times saved!")
	end
end
