local function CmdBet (message, arg)
	local cash, player
	if (#arg >= 3) then
		cash = touint (arg[3])
		player = findPlayer (arg[2])
	else
		cash = touint (arg[2])
		player = source
	end
	if (cash and player) then
		local bet_min_players = SmGetUInt ("bet_min_players", 0)
		if (g_PlayersCount < bet_min_players) then
			privMsg (source, "Not enaught players to bet - %u are needed.", bet_min_players)
		elseif (GbAreBetsPlaced ()) then
			privMsg (source, "Bets are placed!")
		elseif (cash) then
			local rows = DbQuery ("SELECT cash, bidlvl FROM rafalh_players WHERE player=? LIMIT 1", g_Players[source].id)
			local max_bet = SmGetUInt ("max_bet", 0) * rows[1].bidlvl
			if (rows[1].cash < cash) then
				privMsg (source, "You do not have enaught cash!")
			elseif (cash > max_bet) then
				privMsg (source, "Your maximal bet is %s!", formatNumber (max_bet))
			elseif (g_Players[source].bet) then
				privMsg (source, "You already bet %s on %s!", formatMoney (g_Players[source].betcash), getPlayerName (g_Players[source].bet))
			else
				GbBet (source, player, cash)
				privMsg (source, "You bet %s on %s!", formatMoney (cash), getPlayerName (player))
			end
		end
	else privMsg (source, "Usage: %s", arg[1].." [<player>] <cash>") end
end

CmdRegister ("bet", CmdBet, false, "Bets on a player")

local function CmdUnbet (message, arg)
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

CmdRegister ("unbet", CmdUnbet, false, "Cancels your last bet")
