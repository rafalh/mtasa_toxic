CmdMgr.register{
	name = 'fund',
	desc = "Shows current lottery fund",
	func = function(ctx)
		local lotto_limit = Settings.lotto_limit
		scriptMsg("Lottery fund: %s. Max fund: %s.", formatMoney(GbGetLotteryFund()), formatMoney(lotto_limit))
	end
}

CmdMgr.register{
	name = 'roll',
	func = function(ctx)
		if(GbRoll(ctx.player.el)) then
			privMsg(ctx.player, "Rolling the dice...")
		else
			privMsg(ctx.player, "Please Wait... You can roll the dice once every %u seconds.", 30)
		end
	end
}

CmdMgr.register{
	name = 'spin',
	args = {
		{'number', type = 'int', min = 1, max = 65},
		{'cash', type = 'int', min = 1},
	},
	func = function(ctx, num, cash)
		if(GbSpin(ctx.player.el, num, cash)) then
			privMsg(ctx.player, "The wheel is spinning!")
		end
	end
}
