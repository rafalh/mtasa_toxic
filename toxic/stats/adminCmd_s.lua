local function CmdSetAddCash (message, arg)
	local player = (#arg >= 3 and Player.find(arg[2])) or Player.fromEl(source)
	local cash = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (cash) then
		outputServerLog(getPlayerName(source):gsub ('#%x%x%x%x%x%x', '')..' executed: '..arg[1]..' '..getPlayerName(player.el):gsub ('#%x%x%x%x%x%x', '')..' '..cash)
		if (arg[1] == '!addcash' or arg[1] == '/addcash' or arg[1] == 'addcash') then
			cash = cash + player.accountData:get('cash')
		end
		player.accountData:set('cash', cash)
		scriptMsg("%s's cash: %s.", player:getName(), formatMoney(cash))
	else privMsg(source, "Usage: %s", arg[1]..' [<player>] <cash>') end
end

CmdRegister('setcash', CmdSetAddCash, 'command.setmoney')
CmdRegisterAlias ('addcash', 'setcash')

local function CmdSetPoints (message, arg)
	local player = (#arg >= 3 and Player.find(arg[2])) or Player.fromEl(source)
	local pts = toint ((#arg >= 3 and arg[3]) or arg[2])
	
	if (pts) then
		player.accountData:set('points', pts)
		scriptMsg("%s's points: %s.", player:getName(), formatNumber(pts))
	else privMsg(source, "Usage: %s", arg[1]..' [<player>] <points>') end
end

CmdRegister('setpoints', CmdSetPoints, 'resource.'..g_ResName..'.setpoints', "Sets player points")

local function CmdSetBidLevel (message, arg)
	local player = (#arg >= 3 and Player.find(arg[2])) or Player.fromEl(source)
	local bidlvl = touint((#arg >= 3 and arg[3]) or arg[2])
	
	if(bidlvl) then
		player.accountData:set('bidlvl', bidlvl)
		scriptMsg("%s's bidlevel: %u.", player:getName(), bidlvl)
	else privMsg(source, "Usage: %s", arg[1]..' [<player>] <bidlvl>') end
end

CmdRegister('setbidlevel', CmdSetBidLevel, 'resource.'..g_ResName..'.setbidlevel', "Sets player bidlevel")

local function CmdResetStats(message, arg)
	local player = #arg >= 2 and findPlayer (message:sub (arg[1]:len () + 2))
	local pdata = player and Player.fromEl(player)
	if(pdata and pdata.id) then
		DbQuery('DELETE FROM '..BestTimesTable..' WHERE player=?', pdata.id)
		local stats = {cash = 0, bidlvl = 0, points = 0, toptimes_count = 0} -- TODO: reset all stats
		pdata.accountData:set(stats)
		scriptMsg("Statistics has been reset for %s!", getPlayerName(player))
	else privMsg(source, "Usage: %s", arg[1]..' <player>') end
end

CmdRegister('resetstats', CmdResetStats, 'resource.'..g_ResName..'.resetstats', "Resets player statistics")
