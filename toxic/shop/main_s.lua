--------------
-- Includes --
--------------

#include 'include/internal_events.lua'
#include 'include/config.lua'

--------------------------------
-- Local function definitions --
--------------------------------

local VIP_PRICE = 0.6
local g_VipRes = Resource('rafalh_vip')

 -- name = {
	-- cost - item cost,
	-- onBuy - handler (returns true to add item),
	-- onUse - handler (if false this item cannot be used and can be bought only once; returns true to remove item) },
	-- field - database field
g_ShopItems = {}

PlayersTable:addColumns{
	{'bidlvl', 'SMALLINT UNSIGNED', default = 1},
	{'mapBoughtTimestamp', 'INT UNSIGNED', default = 0},
	{'joinmsg', 'VARCHAR(128)', default = false, null = true},
	{'ownedTeam', 'INT', default = false, null = true, fk = {'teams', 'id'}},
	
	{'health100',    'TINYINT UNSIGNED', default = 0},
	{'selfdestr',    'TINYINT UNSIGNED', default = 0},
	{'mines',        'TINYINT UNSIGNED', default = 0},
	{'oil',          'TINYINT UNSIGNED', default = 0},
	{'beers',        'TINYINT UNSIGNED', default = 0},
	{'invisibility', 'TINYINT UNSIGNED', default = 0},
	{'godmodes30',   'TINYINT UNSIGNED', default = 0},
	{'flips',        'TINYINT UNSIGNED', default = 0},
	{'thunders',     'TINYINT UNSIGNED', default = 0},
	{'smoke',        'TINYINT UNSIGNED', default = 0},
	{'spikeStrips',  'TINYINT UNSIGNED', default = 0},
}

function ShpSyncInventory(player)
	local inventory = {}
	
	for itemId, item in pairs(g_ShopItems) do
		if(item.field) then
			inventory[itemId] = player.accountData[item.field]
		end
	end
	
	local isVip = g_VipRes:isReady() and g_VipRes:call('isVip', player.el)
	
	triggerClientInternalEvent(player.el, $(EV_CLIENT_INVENTORY), player.el, inventory, isVip)
end

local function ShpGetInventoryRequest()
	local player = Player.fromEl(client)
	ShpSyncInventory(player)
end

local function ShpBuyShopItemRequest(itemId)
	local item = itemId and g_ShopItems[itemId]
	if(not item) then return end
	
	if(ShpBuyItem(itemId, client)) then
		local player = Player.fromEl(client)
		ShpSyncInventory(player)
	end
end

local function ShpSellShopItemRequest(itemId)
	local item = itemId and g_ShopItems[itemId]
	if(not item) then return end
	
	local pdata = Player.fromEl(client)
	local val = item.field and pdata.accountData:get(item.field)
	
	if(item.onSell(client, val)) then
		pdata.accountData:add('cash', math.floor(item.cost / 2))
		ShpSyncInventory(pdata)
	end
end

local function ShpUseShopItemRequest(itemId)
	local item = itemId and g_ShopItems[itemId]
	if(not item) then return end
	
	if(ShpUseItem(itemId, client)) then
		local player = Player.fromEl(client)
		ShpSyncInventory(player)
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function ShpBuyItem(itemId, player)
	local item = g_ShopItems[itemId]
	local pdata = Player.fromEl(player)
	assert(item and pdata)
	
	if(item.clientSideBuy) then
		RPC('ShpBuyItem', itemId):setClient(player):exec()
		return true
	end
	
	assert(item.onBuy)
	
	local price = ShpGetItemPrice(itemId, player)
	if(pdata.accountData:get('cash') < price) then
		return false
	end
	
	local val = item.field and pdata.accountData:get(item.field)
	local success = item.onBuy(player, val)
	if(success == false) then
		return false
	elseif(success == nil) then
		Debug.warn('Expected returned status ('..tostring(itemId)..')')
	end
	
	pdata.accountData:add('cash', -price)
	
	return price
end

function ShpUseItem(itemId, player)
	local pdata = Player.fromEl(player)
	local item = g_ShopItems[itemId]
	assert(item)
	
	local room = pdata.room
	local map = getCurrentMap(room)
	local disabledShopItems = map and map:getType() and mapType.disabled_shop_items
	if (table.find(disabledShopItems, itemId)) then
		return false
	end

	if(item.onUse) then
		local val = item.field and pdata.accountData:get(item.field)
		
		return item.onUse(player, val)
	end
	
	return false
end

function ShpGetItemPrice(itemId, player)
	local item = g_ShopItems[itemId]
	local price = item.cost
	if(player and not item.noDiscount) then
		local isVip = g_VipRes:isReady() and g_VipRes:call('isVip', player)
		if(isVip) then
			price = math.ceil(price * VIP_PRICE)
		end
	end
	return price
end

function ShpRegisterItem(item)
	assert(type(item) == 'table' and item.id and not g_ShopItems[item.id])
	item.cost = 10000 -- default price
	g_ShopItems[item.id] = item
end

local function ShpPrepareItems()
	for id, item in pairs(g_ShopItems) do
		local itemConfig = Shop.Config.get(id)
		if (itemConfig) then
			item.cost = itemConfig.price
		else
			g_ShopItems[id] = nil
			Debug.info('Disabled Shop item: '..id)
		end
	end
end

------------
-- Events --
------------

addInitFunc(function()
	addInternalEventHandler($(EV_BUY_SHOP_ITEM_REQUEST), ShpBuyShopItemRequest)
	addInternalEventHandler($(EV_SELL_SHOP_ITEM_REQUEST), ShpSellShopItemRequest)
	addInternalEventHandler($(EV_USE_SHOP_ITEM_REQUEST), ShpUseShopItemRequest)
	addInternalEventHandler($(EV_GET_INVENTORY_REQUEST), ShpGetInventoryRequest)
	ShpPrepareItems()
end)
