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

local function GbTryToFinishLottery()
	g_FinishLotteryTimer = nil
	if(not table.empty(g_LotteryPlayers)) then
		GbFinishLottery()
	end
end

local function GbRollTimer(player)
	local n = math.random(1, 6)
	local pdata = Player.fromEl(player)
	
	if(n == 1) then
		local cashsub = math.min(math.random(1000, 9000), pdata.accountData.cash)
		pdata.accountData:add('cash', -cashsub)
		privMsg(player, "You rolled %u, you just lost %s.", n, formatMoney(cashsub))
	elseif(n == 2) then
		local cashadd = math.random(1000, 5000)
		pdata.accountData:add('cash', cashadd)
		privMsg(player, "You rolled %u, %s added to your cash.", n, formatMoney(cashadd))
	elseif(n == 3) then
		privMsg(player, "You rolled %u, which is mute.", n, player)
		if(pdata:mute(60, 'Roll')) then
			outputMsg(g_Root, Styles.red, "%s has been muted after rolling a dice.", pdata:getName(true))
		end
	elseif(n == 4) then
		local cashsub = math.min(math.random(1000, 4000), pdata.accountData.cash)
		pdata.accountData:add('cash', -cashsub)
		privMsg(player, "You rolled %u, you just lost %s.", n, formatMoney(cashsub))
	elseif(n == 5) then
		setSkyGradient(math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255))
		privMsg(player, "You rolled %u, the sky color changes.", n)
	elseif(n == 6) then
		local cashadd = math.random (1000, 10000)
		pdata.accountData:add('cash', cashadd)
		privMsg(player, "You rolled %u, %s added to your cash.", n, formatMoney(cashadd))
	end
end

local function GbSpinTimer(player, n, cash)
	local n2 = math.random(1, 65)
	if(n == n2) then
		local pdata = Player.fromEl(player)
		pdata.accountData:add('cash', cash * 101)
		privMsg(player, "You spinned %u and won %s.", n2, formatMoney(cash*100))
	else
		privMsg(player, "You spinned %u and lost %s.", n2, formatMoney(cash))
	end
end

local function GbLotteryFundInc()
	local lotto_limit = Settings.lotto_limit
	if(g_PlayersCount > 0 and g_LotteryFund < lotto_limit) then
		local max_fund_inc = Settings.max_fund_inc
		local n = math.random(1, max_fund_inc)
		g_LotteryFund = g_LotteryFund + n
		outputMsg(g_Root, Styles.gambling, "Lottery time! %s added to the fund!", formatMoney(n))
		if(g_LotteryFund >= lotto_limit and not g_FinishLotteryTimer) then
			g_FinishLotteryTimer = setTimer(GbTryToFinishLottery, 20000, 1)
		end
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function GbFinishLottery()
	outputMsg(g_Root, Styles.gambling, "Lottery limit reached! Fund: %s.", formatMoney(g_LotteryFund))
	
	local c = 0
	for id, tickets in pairs(g_LotteryPlayers) do
		c = c + tickets
	end
	if(c <= 0) then
		return
	end
	
	local r = math.random(1, c)
	for id, tickets in pairs(g_LotteryPlayers) do
		r = r - tickets
		if(r <= 0) then
			local accountData = AccountData.create(id)
			accountData:add('cash', g_LotteryFund)
			outputMsg(g_Root, Styles.gambling, "%s won the lottery!", accountData:get('name'))
			break
		end
	end
	
	g_LotteryPlayers = {}
	g_LotteryFund = 0
end

function GbCancelLottery()
	for id, tickets in pairs(g_LotteryPlayers) do
		AccountData.create(id):add('cash', tickets)
		local player = Player.fromId(id)
		if(player) then
			privMsg(player.el, "Lottery is cancelled! You get your money (%s) back.", formatMoney(tickets))
		end
	end
end

function GbGetLotteryFund()
	return g_LotteryFund
end

function GbAddLotteryTickets(player, tickets_count)
	local pdata = Player.fromEl(player)
	if(not pdata.id) then
		privMsg(player, "Guests cannot take part in lottery!")
		return false
	end
	
	if ( not g_LotteryPlayers[pdata.id] ) then
		g_LotteryPlayers[pdata.id] = 0
	end
	
	local max_tickets = Settings.max_tickets
	if(g_LotteryPlayers[pdata.id] + tickets_count > max_tickets) then
		privMsg(player, "You can buy only %u tickets more, because maximal number of tickets per player is %u!", max_tickets - g_LotteryPlayers[pdata.id], max_tickets)
		return false
	end
	
	g_LotteryPlayers[pdata.id] = g_LotteryPlayers[pdata.id] + tickets_count
	g_LotteryFund = g_LotteryFund + tickets_count
	
	local lotto_limit = Settings.lotto_limit
	if(not _lottery_time and g_LotteryFund >= lotto_limit) then
		if(not g_FinishLotteryTimer) then
			g_FinishLotteryTimer = setTimer(GbTryToFinishLottery, 1000, 1)
		end
	end
	return true
end

function GbFinishBets(winner)
	if(g_BetsTimer) then
		killTimer(g_BetsTimer)
		g_BetsTimer = false
	end
	
	local mult = math.sqrt(g_PlayersCount)
	
	for player, pdata in pairs(g_Players) do
		if(winner and pdata.bet == winner) then
			local award = math.floor(pdata.betcash * mult)
			pdata.accountData:add('cash', award)
			privMsg(player, "You have won %s in your bet!", formatMoney(award))
		end
		pdata.bet = nil
	end
end

function GbCancelBets()
	for player, pdata in pairs(g_Players) do
		if(pdata.bet) then
			pdata.accountData:add('cash', pdata.betcash)
			privMsg(player, "Your bet is cancelled! You get your money (%s) back.", formatMoney(pdata.betcash))
		end
	end
	GbFinishBets()
end

local function GbRemoveBetsPlayer(player, return_cash)
	for player2, pdata2 in pairs(g_Players) do
		if(pdata2.bet == player) then
			if(return_cash) then
				pdata2.accountData:add('cash', pdata2.betcash)
				privMsg(player2, "Your bet is cancelled! You get your money (%s) back.", formatMoney(pdata2.betcash))
			end
			pdata2.bet = nil
		end
	end
end

local function GbCleanup()
	GbCancelBets()
	GbCancelLottery()
end

local function GbOnPlayerQuit()
	GbRemoveBetsPlayer(source, quitType ~= 'Quit') -- return cash to betters if he quits normally
end

local function GbOnMapStop()
	if(g_BetsTimer) then
		killTimer(g_BetsTimer)
		g_BetsTimer = false
	end
end

local function GbInit()
	local fund_inc_interval = Settings.fund_inc_interval
	if(fund_inc_interval > 0) then
		setTimer(GbLotteryFundInc, fund_inc_interval * 1000, 0)
	end
	
	addEventHandler('onResourceStop', g_ResRoot, GbCleanup)
	addEventHandler('onPlayerQuit', g_Root, GbOnPlayerQuit)
	addEventHandler('onGamemodeMapStop', g_Root, GbOnMapStop)
end

function GbRoll(player)
	local pdata = Player.fromEl(player)
	if(not pdata.last_roll or (getTickCount() - pdata.last_roll) > 30000) then
		pdata.last_roll = getTickCount()
		setPlayerTimer(GbRollTimer, 5000, 1, player)
		return true
	end
	
	return false
end

function GbSpin(player, number, cash)
	local pdata = Player.fromEl(player)
	local ticks = getTickCount()
	if(pdata.last_spin and (ticks - pdata.last_spin) < 30000) then
		privMsg(player, "You cannot spin so often!")
	elseif(number < 1 or number > 65 or cash <= 0 or cash > 100000) then
		privMsg(player, "Invalid number!")
	elseif(pdata.accountData.cash < cash) then
		privMsg(player, "You don't have enough cash!")
	else
		pdata.last_spin = ticks
		pdata.accountData:add('cash', -cash)
		
		-- Create timer
		setPlayerTimer(GbSpinTimer, 5000, 1, player, number, cash)
		return true
	end
	
	return false
end

function GbBet(player, player2, cash)
	local pdata = Player.fromEl(player)
	pdata.accountData:add('cash', -cash)
	pdata.bet = player2
	pdata.betcash = cash
	return true
end

function GbUnbet(player)
	local pdata = Player.fromEl(player)
	if(not pdata.bet) then
		return false
	end
	
	pdata.bet = nil
	pdata.accountData:add('cash', pdata.betcash)
	pdata.betcash = 0
	return true
end

local function GbBetsPlacedTimer()
	outputMsg(g_Root, Styles.gambling, "No More Bets.")
	g_BetsTimer = false
end

function GbStartBets()
	local bet_time = Settings.bet_time
	local bet_min_players = Settings.bet_min_players
	if(bet_time > 0 and g_PlayersCount >= bet_min_players) then
		g_BetsTimer = setTimer(GbBetsPlacedTimer, bet_time * 1000, 1)
		outputMsg(g_Root, Styles.gambling, "Place Your Bets!")
	end
end

function GbAreBetsPlaced()
	if(g_BetsTimer) then
		return false
	end
	return true
end

addInitFunc(GbInit)
