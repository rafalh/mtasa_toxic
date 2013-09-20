--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

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
}

local function ShpGetInventoryRequest ()
	local inventory = {}
	local pdata = Player.fromEl(client)
	
	for item_id, item in pairs ( g_ShopItems ) do
		if(item.field) then
			inventory[item_id] = pdata.accountData:get(item.field)
		end
	end
	
	local isVip = g_VipRes:isReady() and g_VipRes:call('isVip', client)
	
	triggerClientInternalEvent(client, $(EV_CLIENT_INVENTORY), client, inventory, isVip)
end

local function ShpBuyShopItemRequest ( item_id )
	local item = item_id and g_ShopItems[item_id]
	if ( not item ) then return end
	
	if ( ShpBuyItem ( item_id, client ) ) then
		ShpGetInventoryRequest ()
	end
end

local function ShpSellShopItemRequest ( item_id )
	local item = item_id and g_ShopItems[item_id]
	if(not item) then return end
	
	local pdata = Player.fromEl(client)
	local val = item.field and pdata.accountData:get(item.field)
	
	if(item.onSell(client, val)) then
		pdata.accountData:add('cash', item.cost / 2)
		ShpGetInventoryRequest()
	end
end

local function ShpUseShopItemRequest ( item_id )
	local item = item_id and g_ShopItems[item_id]
	if ( not item ) then return end
	
	if ( ShpUseItem ( item_id, client ) ) then
		ShpGetInventoryRequest ()
	end
end

---------------------------------
-- Global function definitions --
---------------------------------

function ShpBuyItem(item_id, player)
	local item = g_ShopItems[item_id]
	local pdata = Player.fromEl(player)
	assert(item and item.onBuy)
	
	local price = ShpGetItemPrice(item_id, player)
	if(pdata.accountData:get('cash') < price) then
		return false
	end
	
	local val = item.field and pdata.accountData:get(item.field)
	local success = item.onBuy(player, val)
	if(success == false) then
		return false
	elseif(success == nil) then
		outputDebugString('Expected returned status ('..tostring(item_id)..')', 2)
	end
	
	pdata.accountData:add('cash', -price)
	
	return price
end

function ShpUseItem(item_id, player)
	local pdata = Player.fromEl(player)
	local item = g_ShopItems[item_id]
	assert(item)
	
	if ( item.onUse ) then
		local val = item.field and pdata.accountData:get(item.field)
		
		return item.onUse(player, val)
	end
	
	return false
end

function ShpGetItemPrice(item_id, player)
	local item = g_ShopItems[item_id]
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
	assert(type(item) == 'table' and item.id and item.cost)
	g_ShopItems[item.id] = item
end

------------
-- Events --
------------

addInitFunc(function()
	addInternalEventHandler ( $(EV_BUY_SHOP_ITEM_REQUEST), ShpBuyShopItemRequest )
	addInternalEventHandler ( $(EV_SELL_SHOP_ITEM_REQUEST), ShpSellShopItemRequest )
	addInternalEventHandler ( $(EV_USE_SHOP_ITEM_REQUEST), ShpUseShopItemRequest )
	addInternalEventHandler ( $(EV_GET_INVENTORY_REQUEST), ShpGetInventoryRequest )
end)
