--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local VIP_COST = 0.6
local g_Cash = 0
local g_ShopList, g_InventoryList
local g_ShopItemCol, g_ShopCostCol
local g_InventoryItemCol, g_InventoryCountCol
local g_CashLabel, g_ItemIcon, g_ItemLabel, g_CostLabel, g_DescrMemo, g_DescrLabel
local g_BuyButton, g_SellButton, g_UseButton
local g_Inventory = {}
local g_IsVip = false

local ShopPanel = {
	name = "Shop",
	img = "img/userpanel/shop.png",
}

--------------------------------
-- Local function definitions --
--------------------------------

local function ShpUpdateButtons ( item_id )
	local item = g_ShopItems[item_id]
	local buy, sell, use = item.getAllowedAct ( g_Inventory[item_id] )
	local cost = item.cost
	if ( g_IsVip ) then
		cost = cost * VIP_COST
	end
	
	guiSetEnabled ( g_BuyButton, buy and g_Cash >= cost )
	guiSetEnabled ( g_SellButton, sell )
	guiSetEnabled ( g_UseButton, use )
end

local function ShpDisableButtons ()
	guiSetEnabled ( g_BuyButton, false )
	guiSetEnabled ( g_SellButton, false )
	guiSetEnabled ( g_UseButton, false )
end

local function ShpUpdateItemInfo ( item_id, is_inventory )
	local item = g_ShopItems[item_id]
	
	if ( item.img ) then
		guiStaticImageLoadImage ( g_ItemIcon, "img/shop/"..item.img )
		guiSetVisible ( g_ItemIcon, true )
	else
		guiSetVisible ( g_ItemIcon, false )
	end
	
	guiSetText ( g_ItemLabel, item.name )
	
	local cost = item.cost
	if ( g_IsVip ) then
		cost = cost * VIP_COST
	end
	local cost_text = MuiGetMsg ( "Cost:" ).." "..formatMoney ( cost )
	if ( g_IsVip ) then
		cost_text = cost_text.." ("..MuiGetMsg ( "%u%% price reduction for VIP" ):format ( 40 )..")"
	end
	guiSetText ( g_CostLabel, cost_text )
	
	guiSetText ( g_DescrMemo, item.descr )
	
	guiSetVisible ( g_BuyButton, not is_inventory )
	guiSetVisible ( g_SellButton, is_inventory )
	guiSetVisible ( g_UseButton, is_inventory )
	
	ShpUpdateButtons ( item_id )
end

local function ShpOnItemsListClick ()
	local row = guiGridListGetSelectedItem ( g_ShopList )
	
	if ( row > -1 ) then -- item is selected
		guiGridListSetSelectedItem ( g_InventoryList, 0, 0 )
		
		local item_id = guiGridListGetItemData ( g_ShopList, row, g_ShopItemCol )
		ShpUpdateItemInfo ( item_id, false )
	else
		ShpDisableButtons ()
	end
end

local function ShpOnInventoryListClick ()
	local row = guiGridListGetSelectedItem ( g_InventoryList )
	
	if ( row > -1 ) then -- item is selected
		guiGridListSetSelectedItem ( g_ShopList, 0, 0 )
		
		local item_id = guiGridListGetItemData ( g_InventoryList, row, g_InventoryItemCol )
		ShpUpdateItemInfo ( item_id, true )
	else
		ShpDisableButtons ()
	end
end

local function ShpBuyClick ()
	local row = guiGridListGetSelectedItem ( g_ShopList )
	
	if ( row > -1 ) then -- item is selected
		local item_id = guiGridListGetItemData ( g_ShopList, row, g_ShopItemCol )
		local item = g_ShopItems[item_id]
		if ( item.onBuy ) then
			item.onBuy ()
		else
			triggerServerInternalEvent ( $(EV_BUY_SHOP_ITEM_REQUEST), g_Me, item_id )
		end
	end
end

local function ShpSellClick ()
	local row = guiGridListGetSelectedItem ( g_InventoryList )
	
	if ( row > -1 ) then -- item is selected
		local item_id = guiGridListGetItemData ( g_InventoryList, row, g_InventoryItemCol )
		triggerServerInternalEvent ( $(EV_SELL_SHOP_ITEM_REQUEST), g_Me, item_id )
	end
end

local function ShpUseClick ()
	local row = guiGridListGetSelectedItem ( g_InventoryList )
	
	if ( row > -1 ) then -- item is selected
		local item_id = guiGridListGetItemData ( g_InventoryList, row, g_InventoryItemCol )
		local item = g_ShopItems[item_id]
		
		if ( item.onUse ) then
			item.onUse ( g_Inventory[item_id] )
		else
			triggerServerInternalEvent ( $(EV_USE_SHOP_ITEM_REQUEST), g_Me, item_id )
		end
	end
end

local function ShpCreateGui ( tab )
	local w, h = guiGetSize ( tab, false )
	
	g_CashLabel = guiCreateLabel ( 10, 15, 160, 15, MuiGetMsg ( "Cash:" ).." "..formatMoney ( g_Cash ), false, tab )
	
	g_ShopList = guiCreateGridList ( 10, 40, 160, ( h - 60 ) / 2, false, tab )
	
	g_ShopItemCol = guiGridListAddColumn ( g_ShopList, "Item", 0.6 )
	g_ShopCostCol = guiGridListAddColumn ( g_ShopList, "Cost", 0.3 )
	
	for item_id, item in pairs ( g_ShopItems ) do
		local row = guiGridListAddRow ( g_ShopList )
		
		guiGridListSetItemText ( g_ShopList, row, g_ShopItemCol, item.name, false, false )
		guiGridListSetItemText ( g_ShopList, row, g_ShopCostCol, formatMoney ( item.cost ), false, false )
		
		guiGridListSetItemData ( g_ShopList, row, g_ShopItemCol, item_id )
	end
	
	addEventHandler ( "onClientGUIClick", g_ShopList, ShpOnItemsListClick, false )
	
	g_InventoryList = guiCreateGridList ( 10, 50 + ( h - 60 ) / 2, 160, ( h - 60 ) / 2, false, tab )
	
	g_InventoryItemCol = guiGridListAddColumn ( g_InventoryList, "Item", 0.6 )
	g_InventoryCountCol = guiGridListAddColumn ( g_InventoryList, "Count", 0.3 )
	
	addEventHandler ( "onClientGUIClick", g_InventoryList, ShpOnInventoryListClick, false )
	
	-- guiCreateStaticImage fails if invalid image is given
	g_ItemIcon = guiCreateStaticImage ( 180, 10, 32, 32, "img/userpanel/shop.png", false, tab )
	guiSetVisible ( g_ItemIcon, false )
	assert ( g_ItemIcon )
	
	g_ItemLabel = guiCreateLabel ( 220, 10, w - 230, 15, "", false, tab )
	guiSetFont ( g_ItemLabel, "default-bold-small" )
	
	g_CostLabel = guiCreateLabel ( 220, 30, w - 230, 15, "Cost:", false, tab )
	
	g_DescrLabel = guiCreateLabel ( 180, 50, 100, 15, "Description:", false, tab )
	
	g_DescrMemo = guiCreateMemo ( 180, 70, w - 190, h - 110, "", false, tab )
	
	g_BuyButton = guiCreateButton ( 180, h - 35, w - 190, 25, "Buy", false, tab )
	addEventHandler ( "onClientGUIClick", g_BuyButton, ShpBuyClick )
	
	g_SellButton = guiCreateButton ( 180, h - 35, ( w - 200 ) / 2, 25, "Sell", false, tab )
	guiSetVisible ( g_SellButton, false )
	addEventHandler ( "onClientGUIClick", g_SellButton, ShpSellClick, false )
	
	g_UseButton = guiCreateButton ( 190 + ( w - 200 ) / 2, h - 35, ( w - 200 ) / 2, 25, "Use", false, tab )
	guiSetVisible ( g_UseButton, false )
	addEventHandler ( "onClientGUIClick", g_UseButton, ShpUseClick, false )
end

function ShopPanel.onShow ( tab )
	if ( not g_ShopList ) then
		ShpCreateGui ( tab )
		ShpUpdateItemInfo ( "joinmsg", false )
		triggerServerInternalEvent ( $(EV_GET_INVENTORY_REQUEST), g_Me )
	end
	
	triggerServerInternalEvent ( $(EV_START_SYNC_REQUEST), g_Me, { stats = g_MyId } )
end

function ShopPanel.onHide ( tab )
	triggerServerInternalEvent ( $(EV_STOP_SYNC_REQUEST), g_Me, { stats = g_MyId } )
end

local function ShpOnSync ( sync_tbl, name, arg, data )
	if ( sync_tbl.stats and sync_tbl.stats[2] and sync_tbl.stats[1] == g_MyId and sync_tbl.stats[2].cash ) then
		g_Cash = sync_tbl.stats[2].cash
		if ( g_CashLabel ) then
			guiSetText ( g_CashLabel, MuiGetMsg ( "Cash:" ).." "..formatMoney ( g_Cash ) )
		end
		if ( g_ShopList ) then -- gui is already created
			local row = guiGridListGetSelectedItem ( g_ShopList )
			local row2 = guiGridListGetSelectedItem ( g_InventoryList )
			local item_id
			
			if ( row > -1 ) then
				item_id = guiGridListGetItemData ( g_ShopList, row, g_ShopItemCol )
			elseif ( row2 > -1 ) then
				item_id = guiGridListGetItemData ( g_InventoryList, row2, g_InventoryItemCol )
			end
			
			if ( item_id ) then
				ShpUpdateButtons ( item_id )
			end
		end
	end
end

local function ShpUpdateInventoryList ()
	if ( not g_ShopList or not g_InventoryList ) then return end
	
	local row = guiGridListGetSelectedItem ( g_InventoryList )
	local old_item = row > -1 and guiGridListGetItemData ( g_InventoryList, row, g_InventoryItemCol )
	
	guiGridListClear ( g_InventoryList )
	
	for item_id, data in pairs ( g_Inventory ) do
		local item = g_ShopItems[item_id]
		if ( item.dataToCount ) then
			local row = guiGridListAddRow ( g_InventoryList )
			local c = item.dataToCount ( data )
			
			if ( c ) then
				guiGridListSetItemText ( g_InventoryList, row, g_InventoryItemCol, item.name, false, false )
				guiGridListSetItemText ( g_InventoryList, row, g_InventoryCountCol, tostring ( c ), false, false )
				
				guiGridListSetItemData ( g_InventoryList, row, g_InventoryItemCol, item_id )
				
				if ( old_item == item_id ) then
					guiGridListSetSelectedItem ( g_InventoryList, row, g_InventoryItemCol )
					ShpUpdateButtons ( item_id )
				end
			end
		end
	end
	
	local row2 = guiGridListGetSelectedItem ( g_ShopList )
	if ( row2 > -1 ) then
		local item_id = guiGridListGetItemData ( g_ShopList, row2, g_ShopItemCol )
		ShpUpdateButtons ( item_id )
	end
end

local function ShpOnChangeLang ()
	if ( g_ShopList ) then
		guiSetText ( g_CashLabel, MuiGetMsg ( "Cash:" ).." "..formatMoney ( g_Cash ) )
		
		-- guiSetText na kolumanch nie dziala, a usuwanie kolumny usuwa zawartosc :/
		
		--guiGridListRemoveColumn ( g_ShopList, g_ShopItemCol )
		--guiGridListAddColumn ( g_ShopList, "Item", 0.6 )
		--guiGridListRemoveColumn ( g_ShopList, g_ShopCostCol )
		--guiGridListAddColumn ( g_ShopList, "Cost", 0.3 )
		
		--guiGridListRemoveColumn ( g_InventoryList, g_InventoryItemCol )
		--guiGridListAddColumn ( g_InventoryList, "Item", 0.6 )
		--guiGridListRemoveColumn ( g_InventoryList, g_InventoryCountCol )
		--guiGridListAddColumn ( g_InventoryList, "Count", 0.3 )
		
		guiSetText ( g_CostLabel, MuiGetMsg ( "Cost:" ) )
	end
end

local FADE_DELAY = 200
local PANEL_ALPHA = 0.6
local g_ItemsWnd = false
local g_ItemsGui = {}
local g_ItemsWndTimer = false

local function ShpUpdateItemsWnd ()
	if ( not g_ItemsWnd ) then return end
	
	for i, el in ipairs ( getElementChildren ( g_ItemsWnd ) ) do
		destroyElement ( el )
	end
	
	-- set big size because static images outside of window are not loaded corectly
	guiSetSize ( g_ItemsWnd, 2000, 100, false )
	
	local x = 0
	local i = 1
	for item_id, item in pairs ( g_ShopItems ) do
		local count = g_Inventory[item_id] and item.dataToCount ( g_Inventory[item_id] ) or 0
		
		if ( count > 0 ) then
			local gui = { id = item_id }
			
			if ( item.img ) then
				gui.img = guiCreateStaticImage ( x + 20, 25, 50, 50, "img/shop/"..item.img, false, g_ItemsWnd )
				assert ( gui.img )
				gui.cnt = guiCreateLabel ( 0, 0, 50, 50, tostring ( count ), false, gui.img )
				guiLabelSetHorizontalAlign ( gui.cnt, "right" )
				guiLabelSetVerticalAlign ( gui.cnt, "bottom" )
				guiSetFont ( gui.cnt, "default-small" )
			end
			
			gui.label = guiCreateLabel ( x, 75, 90, 20, i..". "..MuiGetMsg ( item.name ), false, g_ItemsWnd )
			guiLabelSetHorizontalAlign ( gui.label, "center" )
			guiSetFont ( gui.label, "default-bold-small" )
			
			g_ItemsGui[item_id] = gui
			g_ItemsGui[i] = gui
			
			x = x + 90
			i = i + 1
		end
	end
	
	if ( i == 1 ) then
		local label = guiCreateLabel ( 0, 30, 300, 20, "You don't have any item!", false, g_ItemsWnd )
		guiLabelSetHorizontalAlign ( label, "center" )
		x = 300
	end
	
	local w, h = math.max(x, 200), 100
	local x, y = ( g_ScreenSize[1] - w ) / 2, g_ScreenSize[2] - h - 20
	guiSetSize ( g_ItemsWnd, w, h, false )
	guiSetPosition ( g_ItemsWnd, x, y, false )
	local a = guiGetAlpha ( g_ItemsWnd )
	guiSetAlpha ( g_ItemsWnd, a )
end

local function ShpCreateItemsGui ()
	local w, h = 640, 100
	local x, y = ( g_ScreenSize[1] - w ) / 2, g_ScreenSize[2] - h - 20
	g_ItemsWnd = guiCreateWindow ( x, y, w, h, "User Items", false )
	guiSetVisible ( g_ItemsWnd, false )
	guiWindowSetSizable ( g_ItemsWnd, false )
	
	ShpUpdateItemsWnd ()
end

local function ShpOnItemKeyUp ( key )
	local i = tonumber ( key )
	local gui = g_ItemsGui[i]
	if ( not gui ) then return end
	
	local item_id = gui.id
	local item = g_ShopItems[item_id]
	
	if ( g_Inventory[item_id] ) then
		--outputDebugString ( "Use "..item.name, 2 )
		guiLabelSetColor ( gui.label, 0, 255, 0 )
		setTimer ( function ( label )
			if ( isElement ( label ) ) then
				guiLabelSetColor ( label, 255, 255, 255 )
			end
		end, 1000, 1, gui.label )
		
		if ( item.onUse ) then
			item.onUse ( g_Inventory[item_id] )
		else
			triggerServerInternalEvent ( $(EV_USE_SHOP_ITEM_REQUEST), g_Me, item_id )
		end
	end
	
	resetTimer ( g_ItemsWndTimer )
end

local function ShpHideItems ()
	GaFadeOut ( g_ItemsWnd, FADE_DELAY )
	
	if ( g_ItemsWndTimer ) then
		killTimer ( g_ItemsWndTimer )
		g_ItemsWndTimer = false
	end
	
	for i = 1, 9, 1 do
		unbindKey ( tostring ( i ), "up", ShpOnItemKeyUp )
	end
end

local function ShpShowItems ()
	if ( not g_ItemsWnd ) then
		ShpCreateItemsGui ()
	end
	
	triggerServerInternalEvent ( $(EV_GET_INVENTORY_REQUEST), g_Me )
	
	GaFadeIn ( g_ItemsWnd, FADE_DELAY, PANEL_ALPHA )
	if ( not g_ItemsWndTimer ) then
		g_ItemsWndTimer = setTimer ( ShpHideItems, 5000, 1 )
	end
	
	for i = 1, 9, 1 do
		assert ( bindKey ( tostring ( i ), "up", ShpOnItemKeyUp ) )
	end
end

function ShpToggleItems ()
	if ( not g_ItemsWnd or not guiGetVisible ( g_ItemsWnd ) ) then
		ShpShowItems ()
	else
		ShpHideItems ()
	end
end

local function ShpInit ()
	bindKey ( "F3", "up", ShpToggleItems )
end

local function ShpOnInventory ( inventory, is_vip )
	g_Inventory = inventory
	g_IsVip = is_vip
	
	ShpUpdateInventoryList ()
	ShpUpdateItemsWnd ()
end

function ShpGetInventory ( item_id )
	return g_Inventory[item_id]
end

function ShpSetInventory ( item_id, value )
	g_Inventory[item_id] = value
end

------------
-- Events --
------------

UpRegister ( ShopPanel )
addInternalEventHandler ( $(EV_SYNC), ShpOnSync )
addInternalEventHandler ( $(EV_CLIENT_INVENTORY), ShpOnInventory )
addEventHandler ( "onClientLangChanged", g_ResRoot, ShpOnChangeLang )
addInternalEventHandler ( $(EV_CLIENT_INIT), ShpInit )
