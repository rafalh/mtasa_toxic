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
	desc = "Rolls a dice and gives random event in return",
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
	desc = "Play a Roulette. Guess a number from range 0-36. If you succeed you get in return 40 times more cash than you invested.",
	args = {
		{'number', type = 'int', min = 0, max = 36},
		{'cash', type = 'int', min = 1, max = 100000},
	},
	func = function(ctx, num, cash)
		if(GbSpin(ctx.player.el, num, cash)) then
			privMsg(ctx.player, "The wheel is spinning!")
		end
	end
}
