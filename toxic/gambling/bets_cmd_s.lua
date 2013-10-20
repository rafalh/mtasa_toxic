CmdMgr.register{
	name = 'bet',
	desc = "Bets on a player",
	args = {
		{'cash', type = 'int', min = 1},
		{'player', type = 'player', defVal = false},
	},
	func = function(ctx, cash, targetPlayer)
		if(not targetPlayer) then targetPlayer = ctx.player end
		
		local bet_min_players = Settings.bet_min_players
		local max_bet = Settings.max_bet * ctx.player.accountData:get('bidlvl')
		
		if(g_PlayersCount < bet_min_players) then
			privMsg(ctx.player, "Not enough players to bet - %u are needed.", bet_min_players)
		elseif(GbAreBetsPlaced()) then
			privMsg(ctx.player, "Bets are placed!")
		elseif(ctx.player.accountData:get('cash') < cash) then
			privMsg(ctx.player, "You do not have enough cash!")
		elseif(cash > max_bet) then
			privMsg(ctx.player, "Your maximal bet is %s!", formatNumber(max_bet))
		elseif(ctx.player.bet) then
			privMsg(ctx.player, "You already bet %s on %s!", formatMoney(ctx.player.betcash), getPlayerName(ctx.player.bet))
		else
			GbBet(ctx.player.el, targetPlayer.el, cash)
			privMsg(ctx.player, "You bet %s on %s!", formatMoney(cash), targetPlayer:getName())
		end
	end
}

CmdMgr.register{
	name = 'unbet',
	desc = "Cancels your last bet",
	func = function(ctx)
		if(GbAreBetsPlaced()) then
			privMsg(ctx.player, "Bets are placed!")
		elseif(GbUnbet(ctx.player.el)) then
			privMsg(ctx.player, "You have unbetted!")
		else
			privMsg(ctx.player, "You have not betted!")
		end
	end
}
