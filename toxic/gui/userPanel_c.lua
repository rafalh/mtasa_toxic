-- Variables
local PANEL_COLUMNS = 1
local PANEL_ALPHA = 0.9
local ITEM_W, ITEM_H = 130, 36
local FADE_DELAY = 200
local VIEW_W = 440
local ICON_W, ICON_H = 32, 32

local g_ListStyle = {}
g_ListStyle.normal = {clr = {255, 255, 0}, a = 0.6, fnt = 'default-bold-small'}
g_ListStyle.hover = {clr = {0, 255, 0}, a = 1, fnt = 'default-bold-small'}
g_ListStyle.active = g_ListStyle.hover
g_ListStyle.iconPos = 'left'

local g_Items = {}
local g_Wnd, g_List
local g_UserAvatarView, g_UserLabel, g_LogInOutBtn
local g_CurrentItem = false
local g_Hidden = true
local g_PanelH

-- Functions

local function UpHide()
	if(g_Hidden) then return end
	
	--Debug.info('UpHide')
	GaFadeOut(g_Wnd, FADE_DELAY)
	
	if(g_CurrentItem) then
		if(g_CurrentItem.onHide) then
			g_CurrentItem.onHide(g_CurrentItem.container)
		end
		if(VIEW_W == 0) then
			GaFadeOut(g_CurrentItem.wnd, FADE_DELAY)
			g_CurrentItem = false
		end
	end
	
	showCursor(false)
	g_Hidden = true
end

local function onItemClick(i)
	local item = g_Items[i]
	if(item == g_CurrentItem) then return end
	
	if(item.noWnd) then
		local res = item.onShow()
		if(res and VIEW_W == 0) then
			UpHide()
		end
		return
	end
	
	if(g_CurrentItem) then
		if(g_CurrentItem.onHide) then
			g_CurrentItem.onHide(g_CurrentItem.container)
		end
		guiSetVisible(g_CurrentItem.container, false)
	end
	
	g_CurrentItem = item
	if(not g_CurrentItem.container) then
		if(VIEW_W == 0) then
			local panel_w = g_CurrentItem.width or 450
			local panel_h = g_CurrentItem.height or 380
			local w, h = panel_w, panel_h + 20
			local x = (g_ScreenSize[1] - w) / 2
			local y = (g_ScreenSize[2] - h) / 2
			g_CurrentItem.wnd = guiCreateWindow(x, y, w, h, g_CurrentItem.name, false)
			guiSetVisible(g_CurrentItem.wnd, false)
			guiWindowSetSizable(g_CurrentItem.wnd, false)
			
			g_CurrentItem.container = guiCreateLabel(0, 20, panel_w, panel_h, '', false, g_CurrentItem.wnd)
		else
			g_CurrentItem.container = guiCreateLabel(10 + ITEM_W * PANEL_COLUMNS, 50, VIEW_W, g_PanelH - 80, '', false, g_Wnd)
		end
	else
		guiSetVisible(g_CurrentItem.container, true)
	end
	if(g_CurrentItem.onShow) then
		local prof = DbgPerf()
		g_CurrentItem.onShow(g_CurrentItem.container)
		prof:cp('User Panel -> '..g_CurrentItem.name)
	end
	if(VIEW_W == 0) then
		GaFadeOut(g_Wnd, FADE_DELAY)
		GaFadeIn(g_CurrentItem.wnd, FADE_DELAY, PANEL_ALPHA)
	else
		g_List:setActiveItem(i)
	end
end

local function UpSetAccount(accountName)
	if(not g_UserLabel) then return end
	
	local userMsg = accountName and MuiGetMsg("You are logged in as %s"):format(accountName) or MuiGetMsg("You are not logged in")
	guiSetText(g_UserLabel, userMsg)
	
	guiSetText(g_LogInOutBtn, accountName and "Log Out" or "Log In")
end

local function UpLogInOut()
	if(g_SharedState.accountName) then
		RPC('logOutReq'):exec()
	else
		UpHide()
		openLoginWnd()
	end
end

local function UpGetLocalUserBlockHeight()
	if(AvtOpenGUI) then
		return 50
	else
		return 30
	end
end

local function UpCreateLocalUserBlock(x, y, w, wnd)
	local curX = x + 10
	if(AvatarView) then
		g_UserAvatarView = AvatarView(curX, y, 48, 48, localPlayer, true, wnd)
		curX = curX + 55
	end
	
	g_UserLabel = guiCreateLabel(curX, y, w - 100, 20, '', false, wnd)
	guiSetFont(g_UserLabel, 'default-bold-small')
	
	g_LogInOutBtn = guiCreateButton(x + w - 90, y, 80, 25, "Logout", false, wnd)
	addEventHandler('onClientGUIClick', g_LogInOutBtn, UpLogInOut, false)
	
	UpSetAccount(g_SharedState.accountName)
end

local function UpCreateGui()
	local userH = UpGetLocalUserBlockHeight()
	local w = 10 + ITEM_W * PANEL_COLUMNS + math.max(VIEW_W, 10)
	local h = 100 + userH + ITEM_H * math.ceil(#g_Items / PANEL_COLUMNS)
	local x = (g_ScreenSize[1] - w) / 2
	local y = (g_ScreenSize[2] - h) / 2
	g_Wnd = guiCreateWindow(x, y, w, h, "User Panel", false)
	guiSetVisible(g_Wnd, false)
	guiWindowSetSizable(g_Wnd, false)
	g_PanelH = h
	
	UpCreateLocalUserBlock(0, 20, w, g_Wnd)
	
	local listSize = {ITEM_W * PANEL_COLUMNS, h - 60 - userH}
	local itemSize = {ITEM_W, ITEM_H}
	
	g_List = ListView.create({10, 20 + userH}, listSize, g_Wnd, itemSize, {ICON_W, ICON_H}, g_ListStyle)
	g_List.onClickHandler = onItemClick
	
	for i, item in ipairs(g_Items) do
		g_List:addItem(item.name, item.img, i)
		if(item.tooltip) then
			g_List:setItemTooltip(i, item.tooltip)
		end
	end
	
	if (ServerRules) then
		local link = Link(10, h - 50, 150, 20, g_Wnd, "Server Rules")
		link:setNormalColor('#cc8800')
		addEventHandler('onClientGUIClick', link.el, ServerRules.display, false)
	end
	
	local copyrightLabel = guiCreateLabel(10, h - 25, 230, 15, "Copyright (c) 2009-2014 by rafalh", false, g_Wnd)
	guiLabelSetColor(copyrightLabel, 128, 128, 128)
	
	local verLabel = guiCreateLabel(250, h - 25, 150, 15, '', false, g_Wnd)
	guiLabelSetColor(verLabel, 128, 128, 128)
	RPC('getThisResourceVersion'):onResult(function(ver)
		guiSetText(verLabel, MuiGetMsg("Version: %s"):format(ver))
	end):exec()
	
	local btn = guiCreateButton(w - 70, h - 35, 60, 25, "Close", false, g_Wnd)
	addEventHandler('onClientGUIClick', btn, UpHide, false)
end

local function UpShow()
	if(not g_Hidden) then return end
	
	--Debug.info('UpShow')
	if(not g_Wnd) then
		UpCreateGui()
	end
	
	AchvActivate("Open User Panel")
	GaFadeIn(g_Wnd, FADE_DELAY, PANEL_ALPHA)
	showCursor(true)
	g_Hidden = false
	
	if(VIEW_W > 0) then
		if(not g_CurrentItem) then
			onItemClick(1)
		elseif(g_CurrentItem.onShow) then
			g_CurrentItem.onShow(g_CurrentItem.container)
		end
	end
end

local function UpInit()
	addEventHandler('main.onAccountChange', g_ResRoot, UpSetAccount)
	
	addCommandHandler('UserPanel', UpToggle, false, false)
	local key = getKeyBoundToCommand('UserPanel') or 'F2'
	bindKey(key, 'down', 'UserPanel')
	
	if (g_SharedState.newPlayer) then
		local userPanelKey = getKeyBoundToCommand('UserPanel') or 'F2'
		local statsPanelKey = getKeyBoundToCommand('StatsPanel') or '-'
		outputMsg(Styles.help, "Press %s to open User Panel and %s to open Statistics Panel!", userPanelKey, statsPanelKey)
	end
end

local function UpPostInit()
	table.sort(g_Items, function(a, b)
		return a.prio < b.prio
	end)
	for i, item in ipairs(g_Items) do
		item.idx = i
	end
	
end

addInitFunc(UpInit)
addInitFunc(UpPostInit, 100)

----------------------
-- Global functions --
----------------------

function UpRegister(item)
	assert(g_InitPhase > 0)
	--assert(type(item) == 'table')
	item.prio = item.prio or 0
	table.insert(g_Items, item)
end

function UpToggle()
	--Debug.info('UpToggle g_Hidden '..tostring(g_Hidden))
	if((not g_Wnd or not guiGetVisible(g_Wnd)) and (not g_CurrentItem or VIEW_W > 0)) then
		UpShow()
	elseif(not g_Hidden) then
		UpHide()
	end
end

function UpUpdate(item)
	if(not g_List) then return end
	
	g_List:setItemImg(item.idx, item.img)
	g_List:setItemTooltip(item.idx, item.tooltip)
end

function UpBack()
	if(VIEW_W > 0) then return end
	
	GaFadeOut(g_CurrentItem.wnd, FADE_DELAY)
	if(g_CurrentItem.onHide) then
		g_CurrentItem.onHide(g_CurrentItem.container)
	end
	g_CurrentItem = false
	GaFadeIn(g_Wnd, FADE_DELAY, PANEL_ALPHA)
end

function UpNeedsBackBtn()
	return VIEW_W == 0
end
