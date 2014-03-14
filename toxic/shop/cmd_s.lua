----------------------------------
-- Global functions definitions --
----------------------------------

CmdMgr.register{
	name = 'buy',
	desc = "Buys a shop item",
	args = {
		{'item', type = 'str'},
		{'count', type = 'int', min = 1, defVal = false},
	},
	func = function(ctx, item, count)
		item = item:lower()
		
		if(g_ShopItems[item]) then
			local cost = ShpBuyItem(item, ctx.player.el)
			if(not cost) then
				privMsg(ctx.player, "You cannot buy %s right now.", item)
			elseif(type(cost) == 'number') then
				scriptMsg("%s has bought %s for %s!", ctx.player:getName(), item, formatMoney(cost))
			end
		elseif(item == 'bidlevel') then
			local bidlvl = ctx.player.accountData.bidlvl
			local price = bidlvl * Settings.bidlvl_price
			if(ctx.player.accountData.cash < price) then
				privMsg(ctx.player, "You do not have enough cash! Bid-level costs %s.", formatMoney(price))
			else
				ctx.player.accountData:set({cash = ctx.player.accountData.cash - price, bidlvl = bidlvl + 1})
				local th = ({ 'nd', 'rd' })[bidlvl] or 'th' -- old value
				scriptMsg("%s has bought %s bid-level for %s!", ctx.player:getName(), (bidlvl + 1)..th, formatMoney(price))
			end
		elseif(item == 'lottery' or item == 'lotto' or item == 'lotteryticket') then
			if(not count) then
				privMsg(ctx.player, "Usage: %s", ctx.cmdName..' lottery <tickets count>')
			elseif(ctx.player.accountData.cash < count) then
				privMsg(ctx.player, "You do not have enough cash! You need %s.", formatMoney(count))
			elseif(not GbAddLotteryTickets(ctx.player.el, count)) then
				privMsg(ctx.player, "Failed to buy %u lottery tickets!", count)
			else
				ctx.player.accountData:add('cash', -count)
				scriptMsg("%s bought %u lottery tickets!", ctx.player:getName(), count)
			end
		else privMsg(ctx.player, "There is no item \"%s\"! Use /itemlist to get list of items.", item) end
	end
}

CmdMgr.register{
	name = 'cost',
	desc = "Checks shop item cost",
	args = {
		{'item', type = 'str'},
	},
	func = function(ctx, item)
		item = item:lower()
		if(g_ShopItems[item]) then
			privMsg(ctx.player, "%s costs %s.", item, formatMoney(ShpGetItemPrice(item)))
		elseif(item == 'lottery' or item == 'lotto' or item == 'lotteryticket') then
			privMsg(ctx.player, "1 lottery ticket costs %s.", formatMoney(1))
		elseif(item == 'bidlevel') then
			local bidlvl = ctx.player.accountData.bidlvl
			local price = bidlvl * Settings.bidlvl_price
			privMsg(ctx.player, "Bid-level costs %s.", formatMoney(price))
		else
			privMsg(ctx.player, "There is no item \"%s\"! Use /itemlist to get list of items.", item)
		end
	end
}

CmdMgr.register{
	name = 'itemlist',
	desc = "Displays list of items supported by Shop",
	func = function(ctx)
		local buf = 'bidlevel, lotteryticket'
		for item, _ in pairs(g_ShopItems) do
			buf = buf..', '..item
		end
		scriptMsg("Item list: %s.", buf)
	end
}

CmdMgr.register{
	name = 'use',
	desc = "Uses shop item",
	args = {
		{'item', type = 'str'},
	},
	func = function(ctx, item)
		item = item:lower()
		if(not g_ShopItems[item]) then
			privMsg(ctx.player, "There is no item \"%s\"! Use /itemlist to get list of items.", item)
		elseif(not ShpUseItem(item, ctx.player.el)) then
			privMsg(ctx.player, "You cannot use %s right now!", item)
		else
			privMsg(ctx.player, "You have successfully used %s!", item)
		end
	end
}

CmdMgr.register{
	name = 'setjoinmsg',
	desc = "Sets your Join Message (if you have bought it in Shop before)",
	args = {
		{'newMsg', type = 'str'},
	},
	func = function(ctx, newMsg)
		if(ctx.player.accountData:get('joinmsg')) then
			ctx.player.accountData:set('joinmsg', newMsg)
			privMsg(ctx.player, "You have successfully changed your Join Message!")
		else
			privMsg(ctx.player, "You have not bought Join Message yet!")
		end
	end
}
