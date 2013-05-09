local function CmdBet(message, arg)
	local sourcePlayer = Player.fromEl(source)
	local cash, targetPlayer
	if (#arg >= 3) then
		cash = touint(arg[3])
		local el = findPlayer(arg[2])
		targetPlayer = el and Player.fromEl(el)
	else
		cash = touint(arg[2])
		targetPlayer = sourcePlayer
	end
	if(cash and targetPlayer) then
		local bet_min_players = Settings.bet_min_players
		if(g_PlayersCount < bet_min_players) then
			privMsg (sourcePlayer.el, "Not enough players to bet - %u are needed.", bet_min_players)
		elseif(GbAreBetsPlaced ()) then
			privMsg(sourcePlayer.el, "Bets are placed!")
		elseif (cash) then
			local max_bet = Settings.max_bet * sourcePlayer.accountData:get("bidlvl")
			if(sourcePlayer.accountData:get("cash") < cash) then
				privMsg(sourcePlayer.el, "You do not have enough cash!")
			elseif (cash > max_bet) then
				privMsg(sourcePlayer.el, "Your maximal bet is %s!", formatNumber(max_bet))
			elseif(sourcePlayer.bet) then
				privMsg(sourcePlayer.el, "You already bet %s on %s!", formatMoney(sourcePlayer.betcash), getPlayerName(sourcePlayer.bet))
			else
				GbBet(sourcePlayer.el, targetPlayer.el, cash)
				privMsg(sourcePlayer.el, "You bet %s on %s!", formatMoney(cash), getPlayerName(targetPlayer.el))
			end
		end
	else privMsg(sourcePlayer.el, "Usage: %s", arg[1].." [<player>] <cash>") end
end

CmdRegister("bet", CmdBet, false, "Bets on a player")

local function CmdUnbet(message, arg)
	if (GbAreBetsPlaced ()) then
		privMsg (source, "Bets are placed!")
	else
		if (GbUnbet (source)) then
			privMsg (source, "You have unbetted!")
		else
			privMsg (source, "You have not betted!")
		end
	end
end

CmdRegister("unbet", CmdUnbet, false, "Cancels your last bet")
