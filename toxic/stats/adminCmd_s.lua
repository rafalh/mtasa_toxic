local function CmdSetAddCash (message, arg)
	local playerEl = (#arg >= 3 and findPlayer (arg[2])) or source
	local player = playerEl and Player.fromEl(playerEl)
	local cash = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (cash) then
		outputServerLog(getPlayerName(source):gsub ("#%x%x%x%x%x%x", "").." executed: "..arg[1].." "..getPlayerName(player.el):gsub ("#%x%x%x%x%x%x", "").." "..cash)
		if (arg[1] == "!addcash" or arg[1] == "/addcash" or arg[1] == "addcash") then
			cash = cash + player.accountData:get("cash")
		end
		player.accountData:set("cash", cash)
		scriptMsg(getPlayerName(player.el).."'s cash: "..formatMoney(cash)..".")
	else privMsg(source, "Usage: %s", arg[1].." [<player>] <cash>") end
end

CmdRegister("setcash", CmdSetAddCash, "command.setmoney")
CmdRegisterAlias ("addcash", "setcash")

local function CmdSetPoints (message, arg)
	local playerEl = (#arg >= 3 and findPlayer (arg[2])) or source
	local player = playerEl and Player.fromEl(playerEl)
	local pts = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (pts) then
		player.accountData:set("points", pts)
		scriptMsg(getPlayerName(player.el).."'s points: "..formatNumber(pts)..".")
	else privMsg(source, "Usage: %s", arg[1].." [<player>] <points>") end
end

CmdRegister("setpoints", CmdSetPoints, "resource."..g_ResName..".setpoints", "Sets player points")

local function CmdSetBidLevel (message, arg)
	local playerEl = (#arg >= 3 and findPlayer (arg[2])) or source
	local player = playerEl and Player.fromEl(playerEl)
	local bidlvl = touint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (bidlvl) then
		player.accountData:set("bidlvl", bidlvl)
		scriptMsg(getPlayerName(player).."'s bidlevel: "..bidlvl..".")
	else privMsg(source, "Usage: %s", arg[1].." [<player>] <bidlvl>") end
end

CmdRegister("setbidlevel", CmdSetBidLevel, "resource."..g_ResName..".setbidlevel", "Sets player bidlevel")

local function CmdResetStats(message, arg)
	local player = #arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))
	local pdata = player and Player.fromEl(player)
	if(pdata and pdata.id) then
		DbQuery("DELETE FROM "..BestTimesTable.." WHERE player=?", pdata.id)
		local stats = {
			cash = 0, bidlvl = 0, points = 0, dm = 0, dm_wins = 0,
			first = 0, second = 0, third = 0, toptimes_count = 0 }
		pdata.accountData:set(stats)
		scriptMsg("Statistics has been reset for %s!", getPlayerName(player))
	else privMsg(source, "Usage: %s", arg[1].." <player>") end
end

CmdRegister("resetstats", CmdResetStats, "resource."..g_ResName..".resetstats", "Resets player statistics")
