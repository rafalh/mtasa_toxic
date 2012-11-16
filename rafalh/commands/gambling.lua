local function CmdFund (message, arg)
	local lotto_limit = SmGetUInt ("lotto_limit", 0)
	scriptMsg ("Lottery fund: %s. Max fund: %s.", formatMoney (GbGetLotteryFund ()), formatMoney (lotto_limit))
end

CmdRegister ("fund", CmdFund, false, "Shows current lottery fund")

local function CmdRoll (message, arg)
	if (GbRoll (source)) then
		privMsg (source, "Rolling the dice...")
	else
		privMsg (source, "Please Wait... You can roll the dice once every 30 seconds.")
	end
end

CmdRegister ("roll", CmdRoll, false)

local function CmdSpin (message, arg)
	local num = touint (arg[2])
	local cash = touint (arg[3])
	
	if (num and cash and GbSpin (source, num, cash)) then
		privMsg (source, "The wheel is spinning!")
	else
		privMsg (source, "Usage: %s", arg[1].." <1-65> <cash>")
	end
end

CmdRegister ("spin", CmdSpin, false)
