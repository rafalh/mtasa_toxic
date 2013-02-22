--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local VIP_COST = 0.6
local g_Cash = 0
local g_SelectedItemId
local g_ShopList, g_InventoryList
local g_CashLabel, g_ItemIcon, g_ItemLabel, g_CostLabel, g_DescrMemo
local g_BuyButton, g_SellButton, g_UseButton
local g_Inventory = {}
local g_IsVip = false

local ShopPanel = {
	name = "Shop",
	img = "img/userpanel/shop.png",
	tooltip = "Buy improvments for your car or set next map",
}

--------------------------------
-- Local function definitions --
--------------------------------

local function ShpUpdateButtons ( itemId )
	local item = g_ShopItems[itemId]
	local buy, sell, use = item.getAllowedAct ( g_Inventory[itemId] )
	local cost = item.cost
	if(g_IsVip) then
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

local function ShpUpdateCostLabel(itemId)
	local costStr = MuiGetMsg("Cost:")
	local item = g_ShopItems[itemId]
	if(item) then
		local cost = item.cost
		if(g_IsVip) then
			cost = cost * VIP_COST
		end
		costStr = costStr.." "..formatMoney(cost)
		if(g_IsVip) then
			costStr = costStr.." ("..MuiGetMsg("%u%% price reduction for VIP"):format(100 - VIP_COST*100)..")"
		end
	end
	guiSetText(g_CostLabel, costStr)
end

local function ShpUpdateItemInfo(itemId, isInventory)
	g_SelectedItemId = itemId
	local item = g_ShopItems[itemId]
	
	if(item.img) then
		guiStaticImageLoadImage ( g_ItemIcon, item.img )
		guiSetVisible(g_ItemIcon, true)
	else
		guiSetVisible(g_ItemIcon, false)
	end
	
	guiSetText(g_ItemLabel, item.name)
	ShpUpdateCostLabel(itemId)
	guiSetText(g_DescrMemo, item.descr)
	
	guiSetVisible(g_BuyButton, not isInventory)
	guiSetVisible(g_SellButton, isInventory)
	guiSetVisible(g_UseButton, isInventory)
	
	ShpUpdateButtons(itemId)
end

local function ShpOnItemsListClick(itemId)
	if(itemId) then -- item is selected
		g_ShopList:setActiveItem(itemId)
		g_InventoryList:setActiveItem(false)
		ShpUpdateItemInfo(itemId, false)
	else
		ShpDisableButtons()
	end
end

local function ShpOnInventoryListClick(itemId)
	if(itemId) then -- item is selected
		g_ShopList:setActiveItem(false)
		g_InventoryList:setActiveItem(itemId)
		ShpUpdateItemInfo(itemId, true)
	else
		ShpDisableButtons()
	end
end

local function ShpBuyClick ()
	local itemId = g_ShopList:getActiveItem()
	
	if(itemId) then -- item is selected
		local item = g_ShopItems[itemId]
		if(item.onBuy) then
			item.onBuy()
		else
			triggerServerInternalEvent($(EV_BUY_SHOP_ITEM_REQUEST), g_Me, itemId)
		end
	end
end

local function ShpSellClick ()
	local itemId = g_InventoryList:getActiveItem()
	
	if(itemId) then -- item is selected
		triggerServerInternalEvent($(EV_SELL_SHOP_ITEM_REQUEST), g_Me, itemId)
	end
end

local function ShpUseClick ()
	local itemId = g_InventoryList:getActiveItem()
	
	if(itemId) then -- item is selected
		local item = g_ShopItems[itemId]
		
		if(item.onUse) then
			item.onUse(g_Inventory[itemId])
		else
			triggerServerInternalEvent($(EV_USE_SHOP_ITEM_REQUEST), g_Me, itemId)
		end
	end
end

local function ShpUpdateShopList()
	local oldItemId = g_ShopList:getActiveItem()
	g_ShopList:clear()
	
	for itemId, item in pairs(g_ShopItems) do
		local title = MuiGetMsg(item.name).."\n"..formatMoney(item.cost)
		g_ShopList:addItem(title, item.img, itemId)
		
		if(itemId == oldItemId) then
			g_ShopList:setActiveItem(itemId)
		end
	end
end

local function ShpCreateGui(panel)
	local w, h = guiGetSize(panel, false)
	
	guiCreateStaticImage(10, 10, 32, 32, "img/shop/coins.png", false, panel)
	g_CashLabel = guiCreateLabel(45, 15, 160, 15, formatMoney(g_Cash), false, panel)
	
	local label = guiCreateLabel(10, 45, 160, 15, "All items:", false, panel)
	guiSetFont(label, "default-bold-small")
	
	g_ShopList = ListView.create({10, 60}, {w - 150, (h - 110) * 3/5}, panel, {90, 80})
	g_ShopList.onClickHandler = ShpOnItemsListClick
	ShpUpdateShopList()
	
	local label = guiCreateLabel(10, 75 + (h - 110) * 3/5, 160, 15, "Your items:", false, panel)
	guiSetFont(label, "default-bold-small")
	
	g_InventoryList = ListView.create({10, 90 + (h - 110) * 3/5}, {w - 150, (h - 110) * 2/5}, panel, {90, 80})
	g_InventoryList.onClickHandler = ShpOnInventoryListClick
	
	-- guiCreateStaticImage fails if invalid image is given
	g_ItemIcon = guiCreateStaticImage(w - 130, 10, 32, 32, "img/empty.png", false, panel)
	guiSetVisible(g_ItemIcon, false)
	
	g_ItemLabel = guiCreateLabel(w - 130, 45, 120, 15, "", false, panel)
	guiSetFont(g_ItemLabel, "default-bold-small")
	
	g_CostLabel = guiCreateLabel(w - 130, 60, 120, 50, "Cost:", false, panel)
	guiLabelSetHorizontalAlign(g_CostLabel, "left", true)
	
	guiCreateLabel(w - 130, 100, 120, 15, "Description:", false, panel)
	
	--g_DescrMemo = guiCreateMemo(w - 130, 70, 120, h - 110, "", false, panel)
	g_DescrMemo = guiCreateLabel(w - 130, 115, 120, 100, "", false, panel)
	guiLabelSetHorizontalAlign(g_DescrMemo, "left", true)
	
	g_BuyButton = guiCreateButton(w - 130, h - 70, 120, 25, "Buy", false, panel)
	addEventHandler("onClientGUIClick", g_BuyButton, ShpBuyClick)
	
	g_SellButton = guiCreateButton(w - 130, h - 105, 120, 25, "Sell", false, panel)
	guiSetVisible(g_SellButton, false)
	addEventHandler("onClientGUIClick", g_SellButton, ShpSellClick, false)
	
	g_UseButton = guiCreateButton(w - 130, h - 70, 120, 25, "Use", false, panel)
	guiSetVisible(g_UseButton, false)
	addEventHandler("onClientGUIClick", g_UseButton, ShpUseClick, false)
	
	local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
	addEventHandler("onClientGUIClick", btn, UpBack, false)
end

function ShopPanel.onShow(panel)
	if(not g_ShopList) then
		ShpCreateGui(panel)
		g_ShopList:setActiveItem("nextmap")
		ShpUpdateItemInfo("nextmap", false)
		triggerServerInternalEvent($(EV_GET_INVENTORY_REQUEST), g_Me)
	end
	
	triggerServerInternalEvent($(EV_START_SYNC_REQUEST), g_Me, { stats = g_MyId })
end

function ShopPanel.onHide(panel)
	triggerServerInternalEvent($(EV_STOP_SYNC_REQUEST), g_Me, { stats = g_MyId })
end

local function ShpOnSync(sync_tbl, name, arg, data)
	if(sync_tbl.stats and sync_tbl.stats[2] and sync_tbl.stats[1] == g_MyId and sync_tbl.stats[2].cash) then
		g_Cash = sync_tbl.stats[2].cash
		if(g_CashLabel) then
			guiSetText(g_CashLabel, formatMoney(g_Cash))
		end
		if(g_ShopList) then -- gui is already created
			local itemId = g_ShopList:getActiveItem() or g_InventoryList:getActiveItem()
			
			if(itemId) then
				ShpUpdateButtons(itemId)
			end
		end
	end
end

local function ShpUpdateInventoryList ()
	if (not g_ShopList or not g_InventoryList) then return end
	
	local oldItemId = g_InventoryList:getActiveItem()
	
	g_InventoryList:clear()
	
	for itemId, data in pairs(g_Inventory) do
		local item = g_ShopItems[itemId]
		if(item.dataToCount) then
			local cnt = item.dataToCount(data)
			
			if(cnt) then
				local title = MuiGetMsg(item.name).." ("..tostring(cnt)..")"
				g_InventoryList:addItem(title, item.img, itemId)
				
				if(oldItemId == itemId) then
					g_InventoryList:setActiveItem(itemId)
					ShpUpdateButtons(itemId)
				end
			end
		end
	end
	
	local itemId = g_ShopList:getActiveItem()
	if(itemId) then
		ShpUpdateButtons(itemId)
	end
end

local function ShpOnChangeLang()
	if(g_ShopList) then
		ShpUpdateShopList()
		ShpUpdateInventoryList()
		local itemId = g_ShopList:getActiveItem() or g_InventoryList:getActiveItem()
		ShpUpdateCostLabel(g_SelectedItemId)
	end
end

--------------------------------------------------------------------------------
-- Items window
--------------------------------------------------------------------------------

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
				gui.img = guiCreateStaticImage ( x + 20, 25, 50, 50, item.img, false, g_ItemsWnd )
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

local function ShpCreateItemsGui()
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
	if(not g_ItemsWnd or not guiGetVisible(g_ItemsWnd)) then
		ShpShowItems()
	else
		ShpHideItems()
	end
end

local function ShpInit()
	bindKey("F3", "up", ShpToggleItems)
end

local function ShpOnInventory(inventory, isVip)
	local oldIsVip = g_IsVip
	g_Inventory = inventory
	g_IsVip = isVip
	
	ShpUpdateInventoryList()
	ShpUpdateItemsWnd()
	
	if(oldIsVip ~= isVip and g_ShopList) then
		ShpUpdateCostLabel(g_SelectedItemId)
	end
end

function ShpGetInventory(itemId)
	return g_Inventory[itemId]
end

function ShpSetInventory(itemId, value)
	g_Inventory[itemId] = value
end

------------
-- Events --
------------

UpRegister ( ShopPanel )
addInternalEventHandler ( $(EV_SYNC), ShpOnSync )
addInternalEventHandler ( $(EV_CLIENT_INVENTORY), ShpOnInventory )
addEventHandler ( "onClientLangChanged", g_ResRoot, ShpOnChangeLang )
addInternalEventHandler ( $(EV_CLIENT_INIT), ShpInit )
