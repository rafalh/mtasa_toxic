--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local PANEL_COLUMNS = 4
local PANEL_ALPHA = 0.9
local ITEM_W = 100
local ITEM_H = 100
local FADE_DELAY = 200

local g_ListStyle = {}
g_ListStyle.normal = {clr = {255, 255, 0}, a = 0.6, fnt = "default-bold-small"}
g_ListStyle.hover = {clr = {0, 255, 0}, a = 1, fnt = "default-bold-small"}
g_ListStyle.active = g_ListStyle.hover

local g_Items = {}
local g_Wnd, g_List, g_UserLabel, g_LogInOutBtn
local g_CurrentItem = false
local g_Hiding = false

-- Local functions

function UpBack()
	GaFadeOut(g_CurrentItem.wnd, FADE_DELAY)
	if(g_CurrentItem.onHide) then
		g_CurrentItem.onHide(g_CurrentItem.wnd2)
	end
	g_CurrentItem = false
	GaFadeIn(g_Wnd, FADE_DELAY, PANEL_ALPHA)
end

local function UpHide()
	GaFadeOut(g_Wnd, FADE_DELAY)
	
	if(g_CurrentItem) then
		GaFadeOut(g_CurrentItem.wnd, FADE_DELAY)
		if(g_CurrentItem.onHide) then
			g_CurrentItem.onHide(g_CurrentItem.wnd2)
		end
		g_CurrentItem = false
	end
	
	guiSetInputEnabled(false)
	g_Hiding = true
end

local function onItemClick(i)
	local item = g_Items[i]
	
	if(item.noWnd) then
		local res = item.onShow()
		if(res) then
			UpHide()
		end
		return
	end
	
	g_CurrentItem = item
	guiSetVisible(g_Wnd, false)
	if(not g_CurrentItem.wnd) then
		local panel_w = g_CurrentItem.width or 450
		local panel_h = g_CurrentItem.height or 380
		local w, h = panel_w, panel_h + 20
		local x = (g_ScreenSize[1] - w) / 2
		local y = (g_ScreenSize[2] - h) / 2
		g_CurrentItem.wnd = guiCreateWindow(x, y, w, h, g_CurrentItem.name, false)
		guiSetVisible(g_CurrentItem.wnd, false)
		guiWindowSetSizable(g_CurrentItem.wnd, false)
		
		g_CurrentItem.wnd2 = guiCreateLabel(0, 20, panel_w, panel_h, "", false, g_CurrentItem.wnd)
	end
	if(g_CurrentItem.onShow) then
		g_CurrentItem.onShow(g_CurrentItem.wnd2)
	end
	GaFadeOut(g_Wnd, FADE_DELAY)
	GaFadeIn(g_CurrentItem.wnd, FADE_DELAY, PANEL_ALPHA)
end

local function UpSetAccount(accountName)
	if(not g_UserLabel) then return end
	
	local userMsg = accountName and MuiGetMsg("You are logged in as %s"):format(accountName) or MuiGetMsg("You are not logged in")
	guiSetText(g_UserLabel, userMsg)
	
	guiSetText(g_LogInOutBtn, accountName and "Log Out" or "Log In")
end

local function UpLogInOut()
	if(g_UserName) then
		triggerServerEvent("main.onLogoutReq", g_ResRoot)
	else
		UpHide()
		openLoginWnd()
	end
end

local function UpCreateGui()
	local w = ITEM_W * PANEL_COLUMNS + 20
	local h = 90 + ITEM_H * math.ceil ( #g_Items / PANEL_COLUMNS )
	local x = ( g_ScreenSize[1] - w ) / 2
	local y = ( g_ScreenSize[2] - h ) / 2
	g_Wnd = guiCreateWindow(x, y, w, h, "User Panel", false)
	guiSetVisible(g_Wnd, false)
	guiWindowSetSizable(g_Wnd, false)
	
	g_UserLabel = guiCreateLabel(10, 20, w - 100, 20, "", false, g_Wnd)
	guiSetFont(g_UserLabel, "default-bold-small")
	
	g_LogInOutBtn = guiCreateButton(w - 90, 20, 80, 25, "Logout", false, g_Wnd)
	addEventHandler("onClientGUIClick", g_LogInOutBtn, UpLogInOut, false)
	
	UpSetAccount(g_UserName)
	
	local listSize = {w - 20, h - 90}
	local itemSize = {listSize[1]/PANEL_COLUMNS, ITEM_H}
	
	g_List = ListView.create({10, 50}, listSize, g_Wnd, itemSize, {64, 64}, g_ListStyle)
	g_List.onClickHandler = onItemClick
	
	for i, item in ipairs(g_Items) do
		g_List:addItem(item.name, item.img, i)
	end
	
	local btn = guiCreateButton(w - 70, h - 35, 60, 25, "Close", false, g_Wnd)
	addEventHandler("onClientGUIClick", btn, UpHide, false)
end

local function UpShow()
	if(not g_Wnd) then
		UpCreateGui()
		AchvActivate("Open User Panel")
	end
	
	GaFadeIn(g_Wnd, FADE_DELAY, PANEL_ALPHA)
	guiSetInputEnabled(true)
	g_Hiding = false
end

local function UpInit()
	bindKey(g_ClientSettings.user_panel_key, "up", UpToggle)
end

----------------------
-- Global functions --
----------------------

function UpRegister(item)
	--assert(type(item) == "table")
	item.idx = #g_Items + 1
	table.insert(g_Items, item)
end

function UpToggle()
	if((not g_Wnd or not guiGetVisible(g_Wnd)) and not g_CurrentItem) then
		UpShow()
	elseif(not g_Hiding) then
		UpHide()
	end
end

function UpUpdate(item)
	if(not g_List) then return end
	
	
	g_List:setItemImg(item.idx, item.img)
end

------------
-- Events --
------------

addInternalEventHandler($(EV_CLIENT_INIT), UpInit)
addEventHandler("main.onAccountChange", g_ResRoot, UpSetAccount)
