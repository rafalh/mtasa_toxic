CmdMgr.register{
	name = 'bet',
	desc = "Bets on a player",
	args = {
		{'cash', type = 'int', min = 1},
		{'player', type = 'player', defValFromCtx = 'player'},
	},
	func = function(ctx, cash, targetPlayer)
		local betMinPlayers = Settings.bet_min_players
		local maxBet = Settings.max_bet * ctx.player.accountData:get('bidlvl')
		local targetMap = getCurrentMap(targetPlayer.room)
		
		if(g_PlayersCount < betMinPlayers) then
			privMsg(ctx.player, "Not enough players to bet - %u are needed.", betMinPlayers)
		elseif(GbAreBetsPlaced()) then
			privMsg(ctx.player, "Bets are placed!")
		elseif(ctx.player.accountData:get('cash') < cash) then
			privMsg(ctx.player, "You do not have enough cash!")
		elseif(cash > maxBet) then
			privMsg(ctx.player, "Your maximal bet is %s!", formatNumber(maxBet))
		elseif(ctx.player.bet) then
			privMsg(ctx.player, "You already bet %s on %s!", formatMoney(ctx.player.betcash), getPlayerName(ctx.player.bet))
		elseif(not targetPlayer:isAlive() and targetMap and targetMap:getRespawn()) then
			privMsg(ctx.player, "%s is already dead!", targetPlayer:getName())
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
