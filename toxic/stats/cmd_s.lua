---------------------
-- Local variables --
---------------------

local db_tops = {
	cash = { "Cash", "cash", formatMoney },
	points = { "Points", "points", function (n) return formatNumber (n) end },
	playtime = { "Playtime", "time_here", function (n) return formatTimePeriod (n, 0) end },
	bidlevel = { "Bidlevel", "bidlvl", function (n) return n end }
}
local local_tops = {
	lagger = { "Laggers", getPlayerPing, function (n) return formatNumber (n).." ms" end },
	fps_lagger = { "FPS Laggers", function (player) return -(tonumber (getElementData (player, "fps")) or 0) end, function (n) return formatNumber (-n).." FPS" end }
}

----------------------------------
-- Global functions definitions --
----------------------------------

local function CmdTop (message, arg)
	local top_type = (arg[2] or ""):lower ()
	
	if (db_tops[top_type]) then
		local field = db_tops[top_type][2]
		scriptMsg ("Top "..db_tops[top_type][1]..":")
		rows = DbQuery ("SELECT name, "..field.." FROM "..PlayersTable.." WHERE online=1 AND serial<>'0' ORDER BY "..field.." DESC LIMIT 3")
		for i, data in ipairs (rows) do
			if (db_tops[top_type][3]) then
				data[field] = db_tops[top_type][3] (data[field])
			end
			scriptMsg (i..". "..data.name.." - "..data[field])
		end
	elseif (local_tops[top_type]) then
		scriptMsg ("Top "..local_tops[top_type][1]..":")
		local top = {}
		for player, pdata in pairs (g_Players) do
			if (not pdata.is_console) then
				local n = local_tops[top_type][2] (player)
				
				table.insert (top, { player, n })
			end
		end
		
		table.sort (top, function (row1, row2) return row1[2] > row2[2] end)
		
		for i, toprow in ipairs (top) do
			if (i > 3) then break end
			
			if (local_tops[top_type][3]) then
				toprow[2] = local_tops[top_type][3] (toprow[2])
			end
			
			local name = getPlayerName (toprow[1])
			scriptMsg ("%u. %s - %s", i, name, toprow[2])
		end
	elseif (top_type == "times") then
		BtPrintTopTimes ()
	else
		privMsg (source, "Usage: %s", arg[1].." <type>")
		privMsg (source, "Supported types: %s.", "lagger, fps_lagger, cash, points, playtime, bidlevel, times")
	end
end

CmdRegister ("top", CmdTop, false, "Shows top of given type")

local function CmdGlobalTop (message, arg)
	local top_type = (arg[2] or ""):lower ()
	
	if (db_tops[top_type]) then
		local field = db_tops[top_type][2]
		scriptMsg ("Global Top "..db_tops[top_type][1]..":")
		rows = DbQuery ("SELECT name, "..field.." FROM "..PlayersTable.." WHERE serial<>'0' ORDER BY "..field.." DESC LIMIT 3")
		for i, data in ipairs (rows) do
			if (db_tops[top_type][3]) then
				data[field] = db_tops[top_type][3] (data[field])
			end
			scriptMsg (i..". "..data.name.." - "..data[field])
		end
	else
		privMsg (source, "Usage: %s", arg[1].." <type>")
		privMsg (source, "Supported types: %s.", "cash, points, playtime, bidlevel.")
	end
end

CmdRegister ("gtop", CmdGlobalTop, false, "Shows global top of given type")

local function CmdCash (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local pdata = Player.fromEl(player)
	local stats = pdata.accountData:getTbl()
	scriptMsg ("%s's cash: %s - Bidlevel: %u.", getPlayerName (player), formatMoney (stats.cash), stats.bidlvl)
end

CmdRegister ("cash", CmdCash, false, "Shows player cash and bidlevel")
CmdRegisterAlias ("money", "cash")

local function CmdPoints (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local pdata = Player.fromEl(player)
	local pts = pdata.accountData.points
	scriptMsg ("%s's points: %s.", getPlayerName(player), formatNumber(pts))
end

CmdRegister ("points", CmdPoints, false, "Shows player points count")

local function CmdRank (message, arg)
	local player = (#arg >= 2 and findPlayer(message:sub(arg[1]:len () + 2))) or source
	local pdata = Player.fromEl(player)
	local pts = pdata.accountData.points
	scriptMsg ("%s's rank: %s.", getPlayerName(player), StRankFromPoints(pts))
end

CmdRegister ("rank", CmdRank, false, "Shows player rank title")

local function CmdBidLevel (message, arg)
	local playerEl = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local player = Player.fromEl(playerEl)
	
	scriptMsg("%s's bidlevel: %u.", getPlayerName(player.el), player.accountData.bidlvl)
end

CmdRegister ("bidlevel", CmdBidLevel, false, "Shows player bidlevel")

local function CmdGiveMoney (message, arg)
	local amount = touint (arg[3])
	local dstEl = arg[2] and findPlayer (arg[2])
	local srcPlayer = Player.fromEl(source)
	local dstPlayer = dstEl and Player.fromEl(dstEl)
	
	if (amount and dstPlayer) then
		if (srcPlayer.accountData.cash >= amount) then
			srcPlayer.accountData:add("cash", -amount)
			dstPlayer.accountData:add("cash", amount)
			
			privMsg(source, "%s gave %s %s.", getPlayerName(source), getPlayerName(dstEl), formatMoney(amount))
			privMsg(dstEl, "You received %s from %s.", formatMoney(amount), getPlayerName(source))
		else privMsg(source, "You do not have enough cash!") end
	else privMsg(source, "Usage: %s", arg[1].." <player> <cash>") end
end

CmdRegister ("givemoney", CmdGiveMoney, false, "Transfers money to other player")
CmdRegisterAlias ("givecash", "givemoney")
CmdRegisterAlias ("transfer", "givemoney")

local function CmdSeen (message, arg)
	local player = (#arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))) or source
	local tm = getRealTime (Player.fromEl(player).join_time)
	
	scriptMsg ("%s seen since %d:%02u:%02u.", getPlayerName (player), tm.hour, tm.minute, tm.second)
end

CmdRegister ("seen", CmdSeen, false, "Shows when player joined the game")

local function CmdPlayTime (message, arg)
	local playerEl = (#arg >= 2 and findPlayer(message:sub(arg[1]:len () + 2))) or source
	local player = Player.fromEl(playerEl)
	local playtime = player:getPlayTime()
	scriptMsg("%s's time here: %s.", getPlayerName(player.el), formatTimePeriod(playtime, 0))
end

CmdRegister("playtime", CmdPlayTime, false, "Shows time player spent in game")
CmdRegisterAlias("timehere", "playtime")

local function CmdStats(msg, arg)
	local player = (#arg >= 2 and findPlayer(msg:sub (arg[1]:len() + 2))) or source
	local pdata = Player.fromEl(player)
	local stats = pdata.accountData:getTbl()
	
	local dmRatio = stats.dmVictories/math.max(stats.dmPlayed, 1)
	local huntRatio = stats.huntersTaken/math.max(stats.dmPlayed, 1)
	local ddRatio = stats.ddVictories/math.max(stats.ddPlayed, 1)
	local raceRatio = stats.raceVictories/math.max(stats.racesPlayed, 1)
	
	scriptMsg("%s's statistics:", getPlayerName(player))
	scriptMsg("Points: %s - Maps played: %s - Top Times held: %s - Win Streak: %s", formatNumber(stats.points), formatNumber(stats.mapsPlayed), formatNumber(stats.toptimes_count), formatNumber(stats.maxWinStreak))
	--scriptMsg("DM Victories: %s / %s (%.2f%%)", formatNumber(stats.dmVictories), formatNumber(stats.dmPlayed), dmRatio*100)
	scriptMsg("DM Hunters: %s / %s (%.2f%%)", formatNumber(stats.huntersTaken), formatNumber(stats.dmPlayed), huntRatio*100)
	scriptMsg("DD Victories: %s / %s (%.2f%%)", formatNumber(stats.ddVictories), formatNumber(stats.ddPlayed), ddRatio*100)
	scriptMsg("Race Victories: %s / %s (%.2f%%)", formatNumber(stats.raceVictories), formatNumber(stats.racesPlayed), raceRatio*100)
end

CmdRegister ("stats", CmdStats, false, "Shows player statistics")
CmdRegisterAlias ("stat", "stats")
CmdRegisterAlias ("st", "stats")
