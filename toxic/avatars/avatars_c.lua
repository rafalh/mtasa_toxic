local STYLE = {}
STYLE.normal = {clr = {255, 255, 255}, a = 0.8, fnt = 'default-normal'}
STYLE.hover = {clr = {255, 255, 255}, a = 1, fnt = 'default-normal'}
STYLE.active = {clr = {255, 255, 0}, a = 1, fnt = 'default-bold-small'}
STYLE.iconPos = 'top'

local MIN_LEVEL = false

local g_GUI = false
local g_Avatars = false
g_LocalAvatar = false

addEvent('main.onAvatarChange', true)
addEvent('main.onAvatarsList', true)

function AvtCloseGUI()
	if(not g_GUI) then return end
	
	g_GUI:destroy()
	g_GUI = false
	showCursor(false)
end

local function AvtSaveAndClose()
	local filename = g_GUI.list:getActiveItem()
	if(filename == '') then filename = false end
	
	if(g_LocalAvatar ~= filename) then
		triggerServerEvent('main.onSetAvatarReq', resourceRoot, filename)
	end
	
	AvtCloseGUI()
end

local function AvtHandleListClick(i)
	g_GUI.list:setActiveItem(i)
end

local function AvtUpdateList()
	g_GUI.list:clear()
	
	g_GUI.list:addItem(formatMoney(0), 'img/no_img.png', '')
	
	for filename, cost in pairs(g_Avatars) do
		g_GUI.list:addItem(formatMoney(cost), 'avatars/img/'..filename, filename)
	end
	
	g_GUI.list:setActiveItem(g_LocalAvatar)
end

local function AvtHandleList(avatars)
	g_Avatars = avatars
	if(g_GUI) then
		AvtUpdateList()
	end
end

function AvtOpenGUI()
	if(g_GUI) then return end
	
	if(MIN_LEVEL) then
		local exp = StGet(g_MyId or g_Me, 'points')
		local lvl = exp and LvlFromExp(exp)
		if(not lvl or lvl < MIN_LEVEL) then
			outputMsg(Styles.red, "You need at least %u. level to change your avatar!", MIN_LEVEL)
			return
		end
	end
	
	g_GUI = GUI.create('avatarsWnd')
	local w, h = guiGetSize(g_GUI.wnd, false)
	g_GUI.list = ListView.create({10, 30}, {w - 20, h - 70}, g_GUI.wnd, {64, 80}, {48, 48}, STYLE)
	g_GUI.list.onClickHandler = AvtHandleListClick
	
	if(g_Avatars) then
		AvtUpdateList()
	else
		g_GUI.list:addItem(formatMoney(0), 'img/no_img.png', '')
		RPC('AvtGetList'):onResult(AvtHandleList):exec()
	end
	
	addEventHandler('onClientGUIClick', g_GUI.ok, AvtSaveAndClose, false)
	addEventHandler('onClientGUIClick', g_GUI.cancel, AvtCloseGUI, false)
	showCursor(true)
end

local function AvtHandleChange(newAvatar)
	g_LocalAvatar = newAvatar
end

addEventHandler('main.onAvatarChange', localPlayer, AvtHandleChange, false)
addEventHandler('main.onAvatarsList', resourceRoot, AvtHandleList, false)
