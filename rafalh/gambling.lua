----------------------
-- Global variables --
----------------------

local g_LotteryFund = 0
local g_LotteryPlayers = {}
local g_FinishLotteryTimer = false
local g_BetsTimer = false -- GbAreBetsPlaced uses it

--------------------------------
-- Local function definitions --
--------------------------------

local function GbTryToFinishLottery ()
	g_FinishLotteryTimer = nil
	if ( not table.empty ( g_LotteryPlayers ) ) then
		GbFinishLottery ()
	end
end

local function GbRollTimer ( player )
	local n = math.random ( 1, 6 )
	
	if ( n == 1 ) then
		local cashsub = math.random ( 1000, 9000 )
		StSet ( player, "cash", StGet ( player, "cash" ) - cashsub )
		privMsg ( player, "You rolled %u, you just lost %s.", n, formatMoney ( cashsub ) )
	elseif ( n == 2 ) then
		local cashadd = math.random ( 1000, 5000 )
		StSet ( player, "cash", StGet ( player, "cash" ) + cashadd )
		privMsg ( player, "You rolled %u, %s added to your cash.", n, formatMoney ( cashadd ) )
	elseif ( n == 3 ) then
		privMsg ( player, "You rolled %u, which is mute.", n, player )
		mutePlayer ( player, 60 )
	elseif ( n == 4 ) then
		local cashsub = math.random ( 1000, 4000 )
		StSet ( player, "cash", StGet ( player, "cash" ) - cashsub )
		privMsg ( player, "You rolled %u, you just lost %s.", n, formatMoney ( cashsub ) )
	elseif ( n == 5 ) then
		setSkyGradient ( math.random ( 0,255 ), math.random ( 0,255 ), math.random ( 0,255 ), math.random ( 0,255 ), math.random ( 0,255 ), math.random ( 0,255 ) )
		privMsg ( player, "You rolled %u, the sky color changes.", n )
	elseif ( n == 6 ) then
		local cashadd = math.random ( 1000, 10000 )
		StSet ( player, "cash", StGet ( player, "cash" ) + cashadd )
		privMsg ( player, "You rolled %u, %s added to your cash.", n, formatMoney ( cashadd ) )
	end
end

local function GbSpinTimer ( player, n, cash )
	local n2 = math.random ( 1, 65 )
	if ( n == n2 ) then
		local cash = StGet ( player, "cash" ) + cash * 101
		StSet ( player, "cash", cash )
		privMsg ( player, "You spinned %u and won %s.", n2, formatMoney ( cash*100 ) )
	else
		privMsg ( player, "You spinned %u and lost %s.", n2, formatMoney ( cash ) )
	end
end

local function GbLotteryFundInc ()
	local lotto_limit = SmGetUInt ( "lotto_limit", 0 )
	if ( g_PlayersCount > 0 and g_LotteryFund < lotto_limit ) then
		local max_fund_inc = SmGetUInt ( "max_fund_inc", 1000 )
		local n = math.random ( 1, max_fund_inc )
		g_LotteryFund = g_LotteryFund + n
		scriptMsg ( "Lottery time! %s added to the fund!", formatMoney ( n ) )
		if ( g_LotteryFund >= lotto_limit and not g_FinishLotteryTimer ) then
			g_FinishLotteryTimer = setTimer ( GbTryToFinishLottery, 20000, 1 )
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function GbFinishLottery ()
	scriptMsg ( "Lottery limit reached! Fund: %s.", formatMoney ( g_LotteryFund ) )
	
	local c = 0
	for id, tickets in pairs ( g_LotteryPlayers ) do
		c = c + tickets
	end
	if ( c <= 0 ) then
		return
	end
	
	local r = math.random ( 1, c )
	for id, tickets in pairs ( g_LotteryPlayers ) do
		r = r - tickets
		if ( r <= 0 ) then
			local cash = StGet ( id, "cash" )
			StSet ( id, "cash", cash + g_LotteryFund )
			local rows = DbQuery ( "SELECT name FROM rafalh_players WHERE player=? LIMIT 1", id )
			scriptMsg ( "%s won the lottery!", rows[1].name )
			break
		end
	end
	
	g_LotteryPlayers = {}
	g_LotteryFund = 0
end

function GbCancelLottery ()
	for id, tickets in pairs ( g_LotteryPlayers ) do
		local cash = StGet ( id, "cash" ) + tickets
		StSet ( id, "cash", cash )
		if ( g_IdToPlayer[id] ) then
			privMsg ( g_IdToPlayer[id], "Lottery is canceled! You get your money (%s) back.", formatMoney ( tickets ) )
		end
	end
end

function GbGetLotteryFund ()
	return g_LotteryFund
end

function GbAddLotteryTickets ( player, tickets_count )
	local pdata = g_Players[player]
	if ( not g_LotteryPlayers[pdata.id] ) then
		g_LotteryPlayers[pdata.id] = 0
	end
	
	local max_tickets = SmGetUInt ( "max_tickets", 0 )
	if ( g_LotteryPlayers[pdata.id] + tickets_count > max_tickets ) then
		privMsg ( player, "You can buy only %u tickets more, because maximal number of tickets per player is %u!", max_tickets - g_LotteryPlayers[g_Players[source].id], max_tickets )
		return false
	end
	
	g_LotteryPlayers[pdata.id] = g_LotteryPlayers[pdata.id] + tickets_count
	g_LotteryFund = g_LotteryFund + tickets_count
	
	local lotto_limit = SmGetUInt ( "lotto_limit", 100000 )
	if ( not _lottery_time and g_LotteryFund >= lotto_limit ) then
		if ( not g_FinishLotteryTimer ) then
			g_FinishLotteryTimer = setTimer ( GbTryToFinishLottery, 1000, 1 )
		end
	end
	return true
end

function GbFinishBets ( winner )
	if ( g_BetsTimer ) then
		killTimer ( g_BetsTimer )
		g_BetsTimer = false
	end
	
	local mult = math.sqrt ( g_PlayersCount )
	
	for player, pdata in pairs ( g_Players ) do
		if ( winner and pdata.bet == winner ) then
			local cash_add = math.floor ( pdata.betcash * mult )
			local cash = StGet ( player, "cash" ) + cash_add
			StSet ( player, "cash", cash )
			privMsg ( player, "You have won %s in your bet!", formatMoney ( cash_add ) )
		end
		pdata.bet = nil
	end
end

function GbCancelBets ()
	for player, pdata in pairs ( g_Players ) do
		if ( pdata.bet ) then
			local cash = StGet ( player, "cash" ) + pdata.betcash
			StSet ( player, "cash", cash )
			privMsg ( player, "Your bet is canceled! You get your money (%s) back.", formatMoney ( pdata.betcash ) )
		end
	end
	GbFinishBets ()
end

local function GbRemoveBetsPlayer ( player, return_cash )
	for player2, pdata2 in pairs ( g_Players ) do
		if ( pdata2.bet == player ) then
			if ( return_cash ) then
				local cash = StGet ( player2, "cash" ) + pdata2.betcash
				StSet ( player2, "cash", cash )
				privMsg ( player2, "Your bet is canceled! You get your money (%s) back.", formatMoney ( pdata2.betcash ) )
			end
			pdata2.bet = nil
		end
	end
end

local function GbInit ()
	local fund_inc_interval = SmGetUInt ( "fund_inc_interval", 0 )
	if ( fund_inc_interval > 0 ) then
		setTimer ( GbLotteryFundInc, fund_inc_interval * 1000, 0 )
	end
end

local function GbCleanup ()
	GbCancelBets ()
	GbCancelLottery ()
end

local function GbOnPlayerQuit ()
	GbRemoveBetsPlayer ( source, quitType ~= "Quit" ) -- return cash to betters if he quits normally
end

function GbRoll ( player )
	local pdata = g_Players[player]
	if ( not pdata.last_roll or ( getTickCount() - pdata.last_roll ) > 30000 ) then
		pdata.last_roll = getTickCount ()
		setPlayerTimer ( GbRollTimer, 5000, 1, player )
		return true
	end
	
	return false
end

function GbSpin ( player, number, cash )
	local pdata = g_Players[player]
	if ( pdata.last_spin and ( getTickCount() - pdata.last_spin ) < 30000 ) then
		return false
	end
	
	local pcash = StGet ( player, "cash" )
	
	if ( number >= 1 and number <= 65 and cash > 0 and cash < 100000 and pcash >= cash ) then
		pdata.last_spin = getTickCount ()
		StSet ( player, "cash", pcash - cash )
		
		-- Create timer
		setPlayerTimer ( GbSpinTimer, 5000, 1, player, number, cash )
		return true
	end
	
	return false
end

function GbBet ( player, player2, cash )
	local pdata = g_Players[player]
	StSet ( player, "cash", StGet ( player, "cash" ) - cash )
	pdata.bet = player2
	pdata.betcash = cash
	return true
end

function GbUnbet ( player )
	local pdata = g_Players[player]
	if ( not pdata.bet ) then
		return false
	end
	
	pdata.bet = nil
	StSet ( player, "cash", StGet ( player, "cash" ) + pdata.betcash )
	pdata.betcash = 0
	return true
end

local function GbBetsPlacedTimer ()
	scriptMsg ( "No More Bets." )
	g_BetsTimer = false
end

function GbStartBets ()
	local bet_time = SmGetUInt ( "bet_time", 0 )
	local bet_min_players = SmGetUInt ( "bet_min_players", 0 )
	if ( bet_time > 0 and g_PlayersCount >= bet_min_players ) then
		g_BetsTimer = setTimer ( GbBetsPlacedTimer, bet_time * 1000, 1 )
		scriptMsg ( "Place Your Bets!" )
	end
end

function GbAreBetsPlaced ()
	if ( g_BetsTimer ) then
		return false
	end
	return true
end

local function GbOnMapStop ()
	if ( g_BetsTimer ) then
		killTimer ( g_BetsTimer )
		g_BetsTimer = false
	end
end

addEventHandler ( "onResourceStart", g_ResRoot, GbInit )
addEventHandler ( "onResourceStop", g_ResRoot, GbCleanup )
addEventHandler ( "onPlayerQuit", g_ResRoot, GbOnPlayerQuit )
addEventHandler ( "onGamemodeMapStop", g_Root, GbOnMapStop )
