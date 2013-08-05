----------------------------------
-- Global functions definitions --
----------------------------------

local function CmdBuy (message, arg)
	if (#arg >= 2) then
		local pdata = Player.fromEl(source)
		local item = arg[2]:lower()
		
		if(g_ShopItems[item]) then
			local cost = ShpBuyItem (item, source)
			if (cost) then
				scriptMsg ("%s has bought %s for %s!", getPlayerName (source), item, formatMoney (cost))
			else
				privMsg (source, "You cannot buy %s right now.", item)
			end
		elseif(item == 'bidlevel') then
			local bidlvl = pdata.accountData.bidlvl
			local price = bidlvl * Settings.bidlvl_price
			if (pdata.accountData.cash < price) then
				privMsg (source, "You do not have enough cash! Bid-level costs %s.", formatMoney (price))
			else
				pdata.accountData:set({cash = pdata.accountData.cash - price, bidlvl = bidlvl + 1})
				local th = ({ 'nd', 'rd' })[bidlvl] or 'th' -- old value
				scriptMsg ("%s has bought %s bid-level for %s!", getPlayerName(source), (bidlvl + 1)..th, formatMoney(price))
			end
		elseif(item == 'lottery' or item == 'lotto' or item == 'lotteryticket') then
			local n = touint (arg[3])
			if (n) then
				if (pdata.accountData.cash >= n) then
					if (GbAddLotteryTickets (source, n)) then
						pdata.accountData:add('cash', -n)
						scriptMsg ("%s bought %u lottery tickets!", getPlayerName(source), n)
					end
				else privMsg(source, "You do not have enough cash! You need %s.", formatMoney (n)) end
			else privMsg(source, "Usage: %s", arg[1]..' lottery <tickets count>') end
		else privMsg(source, "There is no item \"%s\"! Use /itemlist to get list of items.", item) end
	else privMsg(source, "Usage: %s", arg[1]..' <item>') end
end

CmdRegister ('buy', CmdBuy, false, "Buys an item")

local function CmdCost (message, arg)
	if(#arg >= 2) then
		local item = message:sub(arg[1]:len () + 2):lower()
		if(g_ShopItems[item]) then
			privMsg(source, "%s costs %s.", item, formatMoney(ShpGetItemPrice(item)))
		elseif(item == 'lottery' or item == 'lotto' or item == 'lotteryticket') then
			privMsg(source, "1 lottery ticket costs %s.", formatMoney(1))
		elseif(item == 'bidlevel') then
			local pdata = Player.fromEl(source)
			local bidlvl = pdata.accountData.bidlvl
			local price = bidlvl * Settings.bidlvl_price
			privMsg(source, "Bid-level costs %s.", formatMoney(price))
		else
			privMsg(source, "There is no item \"%s\"! Use /itemlist to get list of items.", item)
		end
	else privMsg(source, "Usage: %s", arg[1]..' <item>') end
end

CmdRegister ('cost', CmdCost, false, "Checks shop item cost")

local function CmdItemList (message, arg)
	local buf = 'bidlevel, lotteryticket'
	for item, _ in pairs (g_ShopItems) do
		buf = buf..', '..item
	end
	scriptMsg ("Item list: %s.", buf)
end

CmdRegister ('itemlist', CmdItemList, false, "Displays item supported by shop")

local function CmdUse (message, arg)
	local item = message:sub (arg[1]:len () + 2):lower ()
	if (g_ShopItems[item]) then
		if (ShpUseItem (item, source)) then
			privMsg (source, "You have successfully used %s!", item)
		else
			privMsg (source, "You cannot use %s right now!", item)
		end
	else
		privMsg (source, "Usage: %s", arg[1]..' <item>')
	end
end

CmdRegister ('use', CmdUse, false, "Uses shop item")

local function CmdSetJoinMsg(message, arg)
	local sourcePlayer = Player.fromEl(source)
	if (sourcePlayer.accountData:get('joinmsg')) then
		local newMsg = message:sub(arg[1]:len () + 2)
		sourcePlayer.accountData:set('joinmsg', newMsg)
		privMsg(sourcePlayer.el, "You have successfully changed your join message!")
	else
		privMsg(sourcePlayer.el, "You have not bought joinmsg yet!")
	end
end

CmdRegister('setjoinmsg', CmdSetJoinMsg, false, "Sets join message")
