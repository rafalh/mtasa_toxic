local function AvpTimerProc()
	local m = Settings.arit_avg_players_m
	local avg = Settings.avg_players
	
	if(m < 60*24*7) then -- during first week use aritmetic average
		Settings.avg_players = (avg*m + g_PlayersCount)/(m + 1)
		Settings.arit_avg_players_m = m + 1
	else
		Settings.avg_players = avg*0.99993 + g_PlayersCount*0.00007 -- last week has weight of 50%; 0.5^(1/60/24/7)
	end
end

local function AvpInit()
	setTimer(AvpTimerProc, 60000, 0)
end

CmdMgr.register{
	name = 'avgplayers',
	desc = "Shows average players count",
	func = function(ctx)
		scriptMsg("Average players count: %.1f.", Settings.avg_players)
	end
}

addInitFunc(AvpInit)

Settings.register
{
	name = 'avg_players',
	type = 'DOUBLE',
	default = 0,
}

Settings.register
{
	name = 'arit_avg_players_m',
	type = 'INT UNSIGNED',
	default = 0,
}
