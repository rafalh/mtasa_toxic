--------------
-- Includes --
--------------

#include "include/internal_events.lua"

--------------------------------
-- Local function definitions --
--------------------------------

local VIP_PRICE = 0.6

 -- name = {
	-- cost - item cost,
	-- onBuy - handler (returns true to add item),
	-- onUse - handler (if false this item cannot be used and can be bought only once; returns true to remove item) },
	-- field - database field
g_ShopItems = {}

local function ShpGetInventoryRequest ()
	local inventory = {}
	local fields = ""
	
	for item_id, item in pairs ( g_ShopItems ) do
		if ( item.field ) then
			fields = fields..","..item.field
		end
	end
	
	local rows = DbQuery ( "SELECT "..fields:sub ( 2 ).." FROM rafalh_players WHERE player=? LIMIT 1", g_Players[client].id )
	
	for item_id, item in pairs ( g_ShopItems ) do
		if ( item.field ) then
			inventory[item_id] = rows[1][item.field]
		end
	end
	
	local rafalh_vip_res = getResourceFromName ( "rafalh_vip" )
	local is_vip = rafalh_vip_res and getResourceState ( rafalh_vip_res ) == "running" and call ( rafalh_vip_res, "isVip", client )
	
	triggerClientInternalEvent ( client, $(EV_CLIENT_INVENTORY), client, inventory, is_vip )
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
	if ( not item ) then return end
	
	if ( item.field ) then
		local rows = DbQuery ( "SELECT cash, "..item.field.." FROM rafalh_players WHERE player=? LIMIT 1", g_Players[client].id )
		
		if ( item.onSell ( client, rows[1][item.field] ) ) then
			StSet ( client, "cash", rows[1].cash + item.cost / 2 )
			
			ShpGetInventoryRequest ()
		end
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

function ShpBuyItem ( item_id, player )
	local item = g_ShopItems[item_id]
	assert(item and item.onBuy)
	
	local query = "SELECT cash"
	if ( item.field ) then
		query = query..", "..item.field
	end
	query = query.." FROM rafalh_players WHERE player=? LIMIT 1"
	local rows = DbQuery ( query, g_Players[player].id )
	local price = item.cost
	
	local rafalh_vip_res = getResourceFromName ( "rafalh_vip" )
	if ( rafalh_vip_res and getResourceState ( rafalh_vip_res ) == "running" and call ( rafalh_vip_res, "isVip", player ) ) then
		price = math.ceil ( price * VIP_PRICE )
	end
	
	if ( rows[1].cash < price ) then
		return false
	end
	
	local success = item.onBuy ( player, rows[1][item.field] )
	if ( success == false ) then
		return false
	elseif ( success == nil ) then
		outputDebugString ( "Expected returned status", 2 )
	end
	
	StSet ( player, "cash", rows[1].cash - price )
	
	return price
end

function ShpUseItem ( item_id, player )
	local item = g_ShopItems[item_id]
	assert(item)
	
	if ( item.onUse ) then
		local data = false
		if ( item.field ) then
			local rows = DbQuery ( "SELECT "..item.field.." FROM rafalh_players WHERE player=? LIMIT 1", g_Players[player].id )
			data = rows[1][item.field]
		end
		
		return item.onUse ( player, data )
	end
	
	return false
end

function ShpGetItemPrice ( item_id )
	return g_ShopItems[item_id].cost
end

function ShpRegisterItem(item)
	assert(type(item) == "table" and item.id and item.cost)
	g_ShopItems[item.id] = item
end

------------
-- Events --
------------

addInternalEventHandler ( $(EV_BUY_SHOP_ITEM_REQUEST), ShpBuyShopItemRequest )
addInternalEventHandler ( $(EV_SELL_SHOP_ITEM_REQUEST), ShpSellShopItemRequest )
addInternalEventHandler ( $(EV_USE_SHOP_ITEM_REQUEST), ShpUseShopItemRequest )
addInternalEventHandler ( $(EV_GET_INVENTORY_REQUEST), ShpGetInventoryRequest )
