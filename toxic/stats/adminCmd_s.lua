-- Includes
#include 'include/config.lua'

CmdMgr.register{
	name = 'setcash',
	cat = 'Admin',
	accessRight = AccessRight('command.setmoney', true),
	args = {
		{'cash', type = 'int'},
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, cash, player)
		player.accountData.cash = cash
		
		outputServerLog('STATS: '..ctx.player:getName()..' set '..player:getName()..' cash: '..cash)
		scriptMsg("%s's cash: %s.", player:getName(), formatMoney(cash))
	end
}

CmdMgr.register{
	name = 'addcash',
	cat = 'Admin',
	accessRight = AccessRight('command.setmoney', true),
	args = {
		{'amount', type = 'int'},
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, amount, player)
		player.accountData.cash = player.accountData.cash + amount
		
		outputServerLog('STATS: '..ctx.player:getName()..' added '..player:getName()..' cash: '..amount)
		scriptMsg("%s's cash: %s.", player:getName(), formatMoney(player.accountData.cash))
	end
}

CmdMgr.register{
	name = 'setpoints',
	desc = "Sets player points",
	cat = 'Admin',
	aliases = {'setexp'},
	accessRight = AccessRight('setpoints'),
	args = {
		{'points', type = 'int'},
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, points, player)
		player.accountData.points = points
		
		outputServerLog('STATS: '..ctx.player:getName()..' set '..player:getName()..' points: '..points)
		scriptMsg("%s's points: %s.", player:getName(), formatNumber(points))
	end
}

CmdMgr.register{
	name = 'setbidlevel',
	desc = "Sets player bid-level",
	cat = 'Admin',
	accessRight = AccessRight('setbidlevel'),
	args = {
		{'bidlvl', type = 'int'},
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, bidlvl, player)
		player.accountData.bidlvl = bidlvl
		
		outputServerLog('STATS: '..ctx.player:getName()..' set '..player:getName()..' bid-level: '..bidlvl)
		scriptMsg("%s's bid-level: %u.", player:getName(), bidlvl)
	end
}

CmdMgr.register{
	name = 'resetstats',
	desc = "Resets player statistics",
	cat = 'Admin',
	accessRight = AccessRight('resetstats'),
	args = {
		{'player', type = 'player'},
	},
	func = function(ctx, player)
		if(not player.id) then
			privMsg(ctx.player, "Player is not logged in!")
		else
			if(BtDeleteTimes) then
				-- TODO: Fix toptimes_count for other players
				BtDeleteTimes(false, player.id)
			end
			
			-- TODO: reset all stats
			local stats = {cash = 0, bidlvl = 0, points = 0}
#if(TOP_TIMES) then
			stats.toptimes_count = 0
#end
			player.accountData:set(stats)
			
			outputServerLog('STATS: '..ctx.player:getName()..' reset '..player:getName()..' statistics')
			scriptMsg("Statistics have been reset for %s!", player:getName())
		end
	end
}
