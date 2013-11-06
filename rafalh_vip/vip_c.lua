-- Includes
#include '..\\include\\widgets.lua'

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement()
local g_Me = getLocalPlayer()
local g_ScreenSize = { guiGetScreenSize() }
local g_Widgets = {}
local g_WidgetsCount = 0
local g_Settings = {
	widgets = {},
	ignored = {},
	neon = false, neon_clr = '#0080FF',
	vehcolor = false, vehcolor1 = '#000000', vehcolor2 = '#000000',
	vehcolortimer = false, vehcolortimer_int = 1,
	vehlicolor = false, vehlicolor_clr = '#C0C0FF',
	driver = false, driver_id = 0,
	clouds = true,
	blur = false,
	forcevehlion = false,
	paintjob = 0,
	autopilot = false,
	mynametag = false,
	avatar = '',
}
local g_IsVip, g_VipEnd = false, false
local g_Gui
local g_NeonColorWnd, g_VehColorWnd, g_VehColor1Wnd, g_VehColor2Wnd, g_VehLightsColorWnd, g_NametagColorWnd
local g_Skins = false

-------------------
-- Custom events --
-------------------

addEvent('vip.onSettings', true)
addEvent('vip.onReady', true)
addEvent('vip.onVerified', true)
addEvent('onRafalhAddWidget')
addEvent('onRafalhGetWidgets')
addEvent('onRafalhColorDlgClose')
addEvent('vip.onStatus')

--------------------------------
-- Local function definitions --
--------------------------------

local function VipLoadSkins()
	local node = xmlLoadFile(':admin/conf/skins.xml')
	if(not node) then
		outputDebugString('Failed to load skins for VIP panel', 2)
		return
	end
	
	g_Skins = {}
	
	local loaded = {}
	for i, groupNode in ipairs(xmlNodeGetChildren(node)) do
		if(xmlNodeGetName(groupNode) == 'group') then
			for i, skinNode in ipairs(xmlNodeGetChildren(groupNode)) do
				if(xmlNodeGetName(skinNode) == 'skin') then
					local skin = {}
					skin.id = tonumber(xmlNodeGetAttribute(skinNode, 'model'))
					skin.name = xmlNodeGetAttribute(skinNode, 'name')
					if(skin.id and skin.name and not loaded[skin.id]) then
						table.insert(g_Skins, skin)
						loaded[skin.id] = true -- there are duplicates
					end
				end
			end
		end
	end
	
	xmlUnloadFile(node)
	
	table.sort(g_Skins, function(skin1, skin2)
		return skin1.name < skin2.name
	end)
end

local function VipLoadSettings()
	-- Mark settings as loaded even if file does not exist
	g_SettingsLoaded = true
	
	local node = xmlLoadFile('settings.xml')
	if(not node) then return end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local name = xmlNodeGetName(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		local val = xmlNodeGetValue(subnode)
		
		if(name == 'neon') then
			g_Settings.neon =(val == 'true')
			g_Settings.neon_clr = attr.clr and getColorFromString(attr.clr) and attr.clr or '#0080FF'
		elseif(name == 'vehcolor') then
			g_Settings.vehcolor =(val == 'true')
			local clr1 = xmlNodeGetAttribute(subnode, 'clr1')
			local clr2 = xmlNodeGetAttribute(subnode, 'clr2')
			g_Settings.vehcolor1 = attr.clr1 and getColorFromString(attr.clr1) and attr.clr1 or '#000000'
			g_Settings.vehcolor2 = attr.clr2 and getColorFromString(attr.clr2) and attr.clr2 or '#000000'
		elseif(name == 'vehcolortimer') then
			g_Settings.vehcolortimer =(val == 'true')
			g_Settings.vehcolortimer_int = math.max(tonumber(attr.interval) or 3, 3)
		elseif(name == 'vehlicolor') then
			g_Settings.vehlicolor =(val == 'true')
			g_Settings.vehlicolor_clr = attr.clr and getColorFromString(attr.clr) and attr.clr or '#C0C0FF'
		elseif(name == 'driver') then
			g_Settings.driver =(val == 'true')
			g_Settings.driver_id = tonumber(attr.id) or 0
		elseif(name == 'clouds') then
			g_Settings.clouds =(val == 'true')
		elseif(name == 'blur') then
			g_Settings.blur =(val == 'true')
		elseif(name == 'forcevehlion') then
			g_Settings.forcevehlion =(val == 'true')
		elseif(name == 'paintjob') then
			g_Settings.paintjob = tonumber(val) or 0
		elseif(name == 'autopilot') then
			g_Settings.autopilot =(val == 'true')
		elseif(name == 'mynametag') then
			g_Settings.mynametag =(val == 'true')
		elseif(name == 'avatar') then
			g_Settings.avatar = val
		elseif(name == 'ignored') then
			g_Settings.ignored[tostring(val)] = true
		elseif(name == 'widget') then
			if(attr.name) then -- attr.visible
				local widget = {}
				
				local pos = {tonumber(attr.x), tonumber(attr.y)}
				local size = {tonumber(attr.w), tonumber(attr.h)}
				
				if(attr.visible) then
					widget.visible = (attr.visible == 'true')
				end
				if(pos[1] and pos[2]) then
					widget.pos = pos
				end
				if(size[1] and size[2]) then
					widget.size = size
				end
				
				g_Settings.widgets[attr.name] = widget
			end
		end
	end
	
	xmlUnloadFile(node)
end

local function VipSaveSettings()
	local node = xmlCreateFile('settings.xml', 'settings')
	if(not node) then
		outputDebugString('Failed to save VIP settings', 2)
		return
	end
	
	local subnode = xmlCreateChild(node, 'neon')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.neon))
		xmlNodeSetAttribute(subnode, 'clr', g_Settings.neon_clr)
	end
	
	subnode = xmlCreateChild(node, 'vehcolor')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.vehcolor))
		xmlNodeSetAttribute(subnode, 'clr1', g_Settings.vehcolor1)
		xmlNodeSetAttribute(subnode, 'clr2', g_Settings.vehcolor2)
	end
	
	subnode = xmlCreateChild(node, 'vehcolortimer')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.vehcolortimer))
		xmlNodeSetAttribute(subnode, 'interval', g_Settings.vehcolortimer_int)
	end
	
	subnode = xmlCreateChild(node, 'vehlicolor')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.vehlicolor))
		xmlNodeSetAttribute(subnode, 'clr', g_Settings.vehlicolor_clr)
	end
	
	subnode = xmlCreateChild(node, 'driver')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.driver))
		xmlNodeSetAttribute(subnode, 'id', g_Settings.driver_id)
	end
	
	subnode = xmlCreateChild(node, 'clouds')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.clouds))
	end
	
	subnode = xmlCreateChild(node, 'blur')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.blur))
	end
	
	subnode = xmlCreateChild(node, 'forcevehlion')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.forcevehlion))
	end
	
	subnode = xmlCreateChild(node, 'paintjob')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.paintjob))
	end
	
	subnode = xmlCreateChild(node, 'autopilot')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.autopilot))
	end
	
	subnode = xmlCreateChild(node, 'mynametag')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.mynametag))
	end
	
	subnode = xmlCreateChild(node, 'avatar')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.avatar))
	end
	
	for name, _ in pairs(g_Settings.ignored) do
		subnode = xmlCreateChild(node, 'ignored')
		if(subnode) then
			xmlNodeSetValue(subnode, name)
		end
	end
	
	for name, wg in pairs(g_Settings.widgets) do
		subnode = xmlCreateChild(node, 'widget')
		if(subnode) then
			xmlNodeSetAttribute(subnode, 'name', name)
			if(wg.visible ~= nil) then
				xmlNodeSetAttribute(subnode, 'visible', tostring(wg.visible))
			end
			if(wg.pos) then
				xmlNodeSetAttribute(subnode, 'x', wg.pos[1])
				xmlNodeSetAttribute(subnode, 'y', wg.pos[2])
			end
			if(wg.size) then
				xmlNodeSetAttribute(subnode, 'w', wg.size[1])
				xmlNodeSetAttribute(subnode, 'h', wg.size[2])
			end
		end
	end
		
	xmlSaveFile(node)
	xmlUnloadFile(node)
end

local function VipActivateSettings()
	setBlurLevel(( g_Settings.blur and 36) or 0)
	setCloudsEnabled(g_Settings.clouds)
	setElementData(g_Me, 'my_nametag_visible', g_Settings.mynametag, false)
end

local function VipApplySettings()
	g_Settings.neon = guiCheckBoxGetSelected(g_Gui.neon)
	local clr = guiGetText(g_Gui.neon_clr)
	if(getColorFromString(clr)) then -- is color code valid
		g_Settings.neon_clr = clr
	end
	
	g_Settings.vehcolor = guiCheckBoxGetSelected(g_Gui.vehcolor)
	local clr1 = guiGetText(g_Gui.vehcolor1)
	if(getColorFromString(clr1)) then -- is color code valid
		g_Settings.vehcolor1 = clr1
	end
	local clr2 = guiGetText(g_Gui.vehcolor2)
	if(getColorFromString(clr2)) then -- is color code valid
		g_Settings.vehcolor2 = clr2
	end
	
	g_Settings.vehcolortimer = guiCheckBoxGetSelected(g_Gui.vehcolortimer)
	g_Settings.vehcolortimer_int = math.max(tonumber(guiGetText(g_Gui.vehcolortimer_int)) or 3, 3)
	
	g_Settings.vehlicolor = guiCheckBoxGetSelected(g_Gui.vehlicolor)
	local clr = guiGetText(g_Gui.vehlicolor_clr)
	if(getColorFromString(clr)) then -- validate
		g_Settings.vehlicolor_clr = clr
	end
	
	g_Settings.driver = guiCheckBoxGetSelected(g_Gui.driver)
	local skin_i = guiComboBoxGetSelected(g_Gui.driver_id) + 1
	if(g_Skins[skin_i]) then -- FIXME: is it valid?
		g_Settings.driver_id = g_Skins[skin_i].id
		assert(g_Settings.driver_id)
	end
	
	g_Settings.clouds = guiCheckBoxGetSelected(g_Gui.clouds)
	
	g_Settings.blur = guiCheckBoxGetSelected(g_Gui.blur)
	
	g_Settings.forcevehlion = guiCheckBoxGetSelected(g_Gui.forcevehlion)
	
	g_Settings.paintjob = tonumber(guiGetText(g_Gui.paintjob)) or 0
	
	g_Settings.autopilot = guiCheckBoxGetSelected(g_Gui.autopilot)
	
	g_Settings.mynametag = guiCheckBoxGetSelected(g_Gui.mynametag)
	
	g_Settings.avatar = guiGetText(g_Gui.avatar)
	
	g_Settings.ignored = g_Gui.ignored_players
	
	for res_name, wg_name in pairs(g_Widgets) do
		local res = getResourceFromName(res_name)
		local widget_gui = g_Gui.widgets[res_name]
		
		if(res and widget_gui) then
			local widget = g_Settings.widgets[res_name]
			if(not widget) then
				widget = {}
				g_Settings.widgets[res_name] = widget
			end
			
			local visible = guiCheckBoxGetSelected(widget_gui.chb)
			if(widget.visible ~= nil or visible ~= widget_gui.wasVisible) then
				widget.visible = guiCheckBoxGetSelected(widget_gui.chb)
				--call(res, 'widgetCtrl', $(wg_show), widget.visible)
			end
			
			local pos = call(res, 'widgetCtrl', $(wg_getpos))
			if(widget.pos or pos[1] ~= widget_gui.pos[1] or pos[2] ~= widget_gui.pos[2]) then
				widget.pos = pos
			end
			
			local size = call(res, 'widgetCtrl', $(wg_getsize))
			if(widget.size or size[1] ~= widget_gui.size[1] or size[2] ~= widget_gui.size[2]) then
				widget.size = size
			end
		end
	end
	
	VipActivateSettings()
	
	VipSaveSettings()
	
	triggerServerEvent('vip.onSettings', g_Me, g_Settings)
end

local function onWidgetWndMove()
	local name = g_Gui.wgWnd[source]
	local res = getResourceFromName(name)
	if(res) then
		local x, y = guiGetPosition(source, false)
		call(res, 'widgetCtrl', $(wg_move), x, y)
	end
end

local function onWidgetWndSize()
	local name = g_Gui.wgWnd[source]
	local res = getResourceFromName(name)
	if(res) then
		local w, h = guiGetSize(source, false)
		call(res, 'widgetCtrl', $(wg_resize), w, h)
	end
end

local function onWidgetCheckboxClick()
	local name = g_Gui[source]
	local res = getResourceFromName(name)
	if(res) then
		local enabled = guiCheckBoxGetSelected(source)
		local wnd = g_Gui.widgets[name].wnd
		call(res, 'widgetCtrl', $(wg_show), enabled)
		guiSetVisible(wnd, enabled)
		if(enabled) then
			guiBringToFront(g_Gui.widgets[name].wnd)
		end
	end
end

local function onWidgetResetBtnClick()
	local name = g_Gui[source]
	local res = getResourceFromName(name)
	if(res) then
		call(res, 'widgetCtrl', $(wg_reset))
		local pos = call(res, 'widgetCtrl', $(wg_getpos))
		local size = call(res, 'widgetCtrl', $(wg_getsize))
		local enabled = call(res, 'widgetCtrl', $(wg_isshown))
		local wnd = g_Gui.widgets[name].wnd
		guiSetPosition(wnd, pos[1], pos[2], false)
		guiSetSize(wnd, size[1], size[2], false)
		guiCheckBoxSetSelected(g_Gui.widgets[name].chb, enabled)
		guiSetVisible(wnd, enabled)
		
		guiBringToFront(wnd)
	end
end

local function VipCloseSettingsWnd()
	if(not g_Gui) then return end
	
	showCursor(false)
	
	if(g_NeonColorWnd) then
		destroyElement(g_NeonColorWnd)
		g_NeonColorWnd = nil
	end
	if(g_VehColor1Wnd) then
		destroyElement(g_VehColor1Wnd)
		g_VehColor1Wnd = nil
	end
	if(g_VehColor2Wnd) then
		destroyElement(g_VehColor2Wnd)
		g_VehColor2Wnd = nil
	end
	if(g_VehLightsColorWnd) then
		destroyElement(g_VehLightsColorWnd)
		g_VehLightsColorWnd = nil
	end
	if(g_NametagColorWnd) then
		destroyElement(g_NametagColorWnd)
		g_NametagColorWnd = nil
	end
	for wnd, name in pairs(g_Gui.wgWnd) do
		destroyElement(wnd)
		local res = getResourceFromName(name)
		if(res and g_Settings.widgets[name]) then
			if(g_Settings.widgets[name].pos) then
				call(res, 'widgetCtrl', $(wg_move), g_Settings.widgets[name].pos[1], g_Settings.widgets[name].pos[2])
			end
			if(g_Settings.widgets[name].size) then
				call(res, 'widgetCtrl', $(wg_resize), g_Settings.widgets[name].size[1], g_Settings.widgets[name].size[2])
			end
			if(g_Settings.widgets[name].visible ~= nil) then
				call(res, 'widgetCtrl', $(wg_show), g_Settings.widgets[name].visible)
			end
		end
	end
	destroyElement(g_Gui.wnd)
	g_Gui = nil
end

local function VipOpenSettingsWnd()
	if(g_Gui) then
		guiBringToFront(g_Gui.wnd)
		return
	end
	
	local w = 410
	local h = math.min(math.max(420, g_WidgetsCount*25, 120) + 125, g_ScreenSize[2])
	local x, y =(g_ScreenSize[1] - w) / 2,(g_ScreenSize[2] - h) / 2
	
	g_Gui = {}
	g_Gui.wnd = guiCreateWindow(x, y, w, h, "VIP Panel", false)
	guiWindowSetMovable(g_Gui.wnd, true)
	guiWindowSetSizable(g_Gui.wnd, true)
	guiBringToFront(g_Gui.wnd)
	
	local tab_panel = guiCreateTabPanel(10, 20, w - 20, h - 80, false, g_Gui.wnd)
	assert(tab_panel)
	local tab, button
	local rafalh_shared_res = getResourceFromName('rafalh_shared')
	
	if(g_VipEnd) then
		local now = getRealTime().timestamp
		local days_left =(g_VipEnd - now) / 3600 / 24
		local tm = getRealTime(g_VipEnd)
		local label = guiCreateLabel(10, h - 55, w - 20, 20, "Your VIP rank will be valid untill "..( "%u.%02u.%u %u:%02u GMT."):format(tm.monthday, tm.month+1, tm.year+1900, tm.hour, tm.minute).." ("..math.floor(days_left).." days left).", false, g_Gui.wnd)
		if(days_left <= 3) then
			guiLabelSetColor(label, 255, 0, 0)
		end
	else
		local label = guiCreateLabel(10, h - 55, w - 20, 20, "Your VIP rank has no timelimit.", false, g_Gui.wnd)
		guiLabelSetColor(label, 0, 128, 0)
	end
	button = guiCreateButton(330, h - 30, 60, 20, "Cancel", false, g_Gui.wnd)
	addEventHandler('onClientGUIClick', button, VipCloseSettingsWnd, false)
	
	button = guiCreateButton(260, h - 30, 60, 20, "OK", false, g_Gui.wnd)
	addEventHandler('onClientGUIClick', button, function()
		VipApplySettings()
		VipCloseSettingsWnd()
	end, false)
	
	-- Vehicle
	tab = guiCreateTab("Vehicle", tab_panel)
	local y = 10
	
	g_Gui.neon = guiCreateCheckBox(10, y, 300, 25, "Neon under the car", g_Settings.neon, false, tab)
	guiCreateLabel(10, y + 30, 40, 20, "Color:", false, tab)
	g_Gui.neon_clr = guiCreateEdit(50, y + 25, 65, 25, g_Settings.neon_clr, false, tab)
	button = guiCreateButton(120, y + 30, 60, 20, "Choose", false, tab)
	addEventHandler('onClientGUIClick', button, function()
		if(g_NeonColorWnd) then
			guiBringToFront(g_NeonColorWnd)
		else
			local r, g, b = getColorFromString(guiGetText(g_Gui.neon_clr))
			g_NeonColorWnd = call(rafalh_shared_res, 'createColorDlg', 'onRafalhColorDlgClose', r, g, b)
			addEventHandler('onRafalhColorDlgClose', g_NeonColorWnd, function(r, g, b)
				if(r) then
					guiSetText(g_Gui.neon_clr,('#%02X%02X%02X'):format(r, g, b))
				end
				g_NeonColorWnd = nil
			end, false)
		end
	end, false)
	y = y + 65
	
	g_Gui.vehcolor = guiCreateCheckBox(10, y, 300, 25, "Car's color", g_Settings.vehcolor, false, tab)
	guiCreateLabel(10, y + 30, 50, 20, "Color 1:", false, tab)
	g_Gui.vehcolor1 = guiCreateEdit(60, y + 25, 65, 25, g_Settings.vehcolor1, false, tab)
	button = guiCreateButton(130, y + 30, 60, 20, "Choose", false, tab)
	addEventHandler('onClientGUIClick', button, function()
		if(g_VehColor1Wnd) then
			guiBringToFront(g_VehColor1Wnd)
		else
			local r, g, b = getColorFromString(guiGetText(g_Gui.vehcolor1))
			g_VehColor1Wnd = call(rafalh_shared_res, 'createColorDlg', 'onRafalhColorDlgClose', r, g, b)
			addEventHandler('onRafalhColorDlgClose', g_VehColor1Wnd, function(r, g, b)
				if(r) then
					guiSetText(g_Gui.vehcolor1,('#%02X%02X%02X'):format(r, g, b))
				end
				g_VehColor1Wnd = nil
			end, false)
		end
	end, false)
	guiCreateLabel(195, y + 30, 50, 20, "Color 2:", false, tab)
	g_Gui.vehcolor2 = guiCreateEdit(245, y + 25, 65, 25, g_Settings.vehcolor2, false, tab)
	button = guiCreateButton(315, y + 30, 60, 20, "Choose", false, tab)
	addEventHandler('onClientGUIClick', button, function()
		if(g_VehColor2Wnd) then
			guiBringToFront(g_VehColor2Wnd)
		else
			local r, g, b = getColorFromString(guiGetText(g_Gui.vehcolor2))
			g_VehColor2Wnd = call(rafalh_shared_res, 'createColorDlg', 'onRafalhColorDlgClose', r, g, b)
			addEventHandler('onRafalhColorDlgClose', g_VehColor2Wnd, function(r, g, b)
				if(r) then
					guiSetText(g_Gui.vehcolor2,('#%02X%02X%02X'):format(r, g, b))
				end
				g_VehColor2Wnd = nil
			end, false)
		end
	end, false)
	y = y + 65
	
	g_Gui.vehcolortimer = guiCreateCheckBox(10, y, 300, 25, "Random car's color timer", g_Settings.vehcolortimer, false, tab)
	guiCreateLabel(10, y + 30, 80, 20, "Interval (sec.):", false, tab)
	g_Gui.vehcolortimer_int = guiCreateEdit(100, y + 25, 40, 25, tostring(g_Settings.vehcolortimer_int), false, tab)
	y = y + 65
	
	g_Gui.vehlicolor = guiCreateCheckBox(10, y, 300, 25, "Car's lights color", g_Settings.vehlicolor, false, tab)
	guiCreateLabel(10, y + 30, 40, 20, "Color:", false, tab)
	g_Gui.vehlicolor_clr = guiCreateEdit(50, y + 25, 80, 25, g_Settings.vehlicolor_clr, false, tab)
	button = guiCreateButton(140, y + 30, 60, 20, "Choose", false, tab)
	addEventHandler('onClientGUIClick', button, function()
		if(g_VehLightsColorWnd) then
			guiBringToFront(g_VehLightsColorWnd)
		else
			local r, g, b = getColorFromString(guiGetText(g_Gui.vehlicolor_clr))
			g_VehLightsColorWnd = call(rafalh_shared_res, 'createColorDlg', 'onRafalhColorDlgClose', r, g, b)
			addEventHandler('onRafalhColorDlgClose', g_VehLightsColorWnd, function(r, g, b)
				if(r) then
					guiSetText(g_Gui.vehlicolor_clr,('#%02X%02X%02X'):format(r, g, b))
				end
				g_VehLightsColorWnd = nil
			end, false)
		end
	end, false)
	y = y + 65
	
	g_Gui.driver = guiCreateCheckBox(10, y, 300, 25, "Driver", g_Settings.driver, false, tab)
	g_Gui.driver_id = guiCreateComboBox(10, y + 25, 150, 300, tostring(g_Settings.driver_id), false, tab)
	local default = -1
	for i, skin in ipairs(g_Skins) do
		local id = guiComboBoxAddItem(g_Gui.driver_id, skin.name)
		if(g_Settings.driver_id == skin.id) then
			default = id
		end
	end
	guiComboBoxSetSelected(g_Gui.driver_id, default)
	y = y + 65
	
	g_Gui.forcevehlion = guiCreateCheckBox(10, y, 300, 25, "Force car's lights on", g_Settings.forcevehlion, false, tab)
	y = y + 30
	
	guiCreateLabel(10, y + 5, 50, 20, "Paintjob:", false, tab)
	g_Gui.paintjob = guiCreateEdit(70, y, 40, 25, tostring(g_Settings.paintjob), false, tab)
	y = y + 40
	
	g_Gui.autopilot = guiCreateCheckBox(10, y, 300, 25, "Autopilot", g_Settings.autopilot, false, tab)
	
	-- Ignore
	tab = guiCreateTab("Ignore", tab_panel)
	
	g_Gui.ignored_list = guiCreateGridList(10, 10,(380 - 100)/2, h - 120, false, tab)
	g_Gui.ignored_col = guiGridListAddColumn( g_Gui.ignored_list, "Ignored players", 0.8)
	-- copy g_Settings.ignored to g_Gui.ignored_players[name]
	g_Gui.ignored_players = {}
	for name, v in pairs(g_Settings.ignored) do
		g_Gui.ignored_players[name] = v
	end
	
	for name, v in pairs(g_Gui.ignored_players) do
		local row = guiGridListAddRow(g_Gui.ignored_list)
		guiGridListSetItemText(g_Gui.ignored_list, row, g_Gui.ignored_col, name, false, false)
	end
	
	g_Gui.players_list = guiCreateGridList(90 +(380 - 100)/2, 10,(380 - 100)/2, h - 120, false, tab)
	g_Gui.players_col = guiGridListAddColumn( g_Gui.players_list, "Players online", 0.8)
	
	for i, player in ipairs(getElementsByType('player')) do
		local row = guiGridListAddRow(g_Gui.players_list)
		guiGridListSetItemText(g_Gui.players_list, row, g_Gui.players_col, getPlayerName(player):gsub('#%x%x%x%x%x%x', ''), false, false)
	end
	
	button = guiCreateButton(20 +(380 - 100)/2, 10, 60, 20, "Add", false, tab)
	addEventHandler('onClientGUIClick', button, function()
		local row, col = guiGridListGetSelectedItem(g_Gui.players_list)
		local name = guiGridListGetItemText(g_Gui.players_list, row, col)
		if(name and not g_Gui.ignored_players[name]) then
			g_Gui.ignored_players[name] = true
			local row = guiGridListAddRow(g_Gui.ignored_list)
			guiGridListSetItemText(g_Gui.ignored_list, row, g_Gui.ignored_col, name, false, false)
		end
	end, false)
	button = guiCreateButton(20 +(380 - 100)/2, 40, 60, 20, "Delete", false, tab)
	addEventHandler('onClientGUIClick', button, function()
		local row, col = guiGridListGetSelectedItem(g_Gui.ignored_list)
		local name = guiGridListGetItemText(g_Gui.ignored_list, row, col)
		if(name) then
			g_Gui.ignored_players[name] = nil
			guiGridListRemoveRow(g_Gui.ignored_list, row)
		end
	end, false)
	
	-- Widgets
	tab = guiCreateTab("Widgets", tab_panel)
	
	local lang = getElementData(g_Me, 'lang')
	local y = 10
	g_Gui.widgets = {}
	g_Gui.wgWnd = {}
	for name, title in pairs(g_Widgets) do
		local res = getResourceFromName(name)
		if(res) then
			local visible = call(res, 'widgetCtrl', $(wg_isshown))
			local pos = call(res, 'widgetCtrl', $(wg_getpos))
			local size = call(res, 'widgetCtrl', $(wg_getsize))
			
			if(type(title) == 'table') then
				if(title[lang]) then
					title = title[lang]
				else
					title = title[1]
				end
			end
			
			local widget = {}
			g_Gui.widgets[name] = widget
			widget.chb = guiCreateCheckBox(10, y, 150, 25, title, visible, false, tab)
			g_Gui[widget.chb] = name
			addEventHandler('onClientGUIClick', widget.chb, onWidgetCheckboxClick, false)
			local btn = guiCreateButton(170, y, 50, 20, "Reset", false, tab)
			g_Gui[btn] = name
			addEventHandler('onClientGUIClick', btn, onWidgetResetBtnClick, false)
			widget.wasVisible = visible
			widget.pos = pos
			widget.size = size
			
			widget.wnd = guiCreateWindow(pos[1], pos[2], size[1], size[2], title, false)
			g_Gui.wgWnd[widget.wnd] = name
			guiWindowSetMovable(widget.wnd, true)
			guiWindowSetSizable(widget.wnd, true)
			guiSetAlpha(widget.wnd, 0.5)
			guiSetVisible(widget.wnd, visible)
			addEventHandler('onClientGUIMove', widget.wnd, onWidgetWndMove, false)
			addEventHandler('onClientGUISize', widget.wnd, onWidgetWndSize, false)
			y = y + 25
		end
	end
	
	-- Other
	tab = guiCreateTab("Other", tab_panel)
	local w, h = guiGetSize(tab, false)
	y = 10
	
	g_Gui.clouds = guiCreateCheckBox(10, y, w - 20, 25, "Show clouds", g_Settings.clouds, false, tab)
	y = y + 30
	
	g_Gui.blur = guiCreateCheckBox(10, y, w - 20, 25, "Motion blur", g_Settings.blur, false, tab)
	y = y + 30
	
	g_Gui.mynametag = guiCreateCheckBox(10, y, w - 20, 25, "Show my nametag", g_Settings.mynametag, false, tab)
	y = y + 30
	
	guiCreateLabel(10, y + 5, w - 20, 20, "Avatar URL address:", false, tab)
	g_Gui.avatar = guiCreateEdit(10, y + 25, w - 20, 25, g_Settings.avatar, false, tab)
	y = y + 60
	
	guiSetInputMode('no_binds_when_editing')
	showCursor(true)
end

local function VipToggleSettingsWnd()
	if(g_Gui) then
		VipCloseSettingsWnd()
	else
		VipOpenSettingsWnd()
	end
end

local function VipOnClientVip(timestamp)
	g_VipEnd = timestamp
	
	if(not g_Skins) then
		VipLoadSkins()
	end
	if(not g_SettingsLoaded) then
		VipLoadSettings()
	end
	
	if(g_IsVip) then
		return
	end
	
	g_IsVip = true
	
	outputChatBox("You are a VIP! Press \"g\" to access VIP settings.", 255, 0, 0)
	
	triggerServerEvent('vip.onSettings', g_Me, g_Settings)
	
	VipActivateSettings()
	
	bindKey('g', 'down', VipToggleSettingsWnd)
	
	triggerEvent('vip.onStatus', resourceRoot, g_IsVip)
	triggerEvent('onRafalhGetWidgets', g_Root)
end

local function VipOnAddWidget(res, widgetName)
	--[[if(sourceResource ~= res) then
		outputDebugString(getResourceName(sourceResource)..' <> '..getResourceName(res), 2)
	end]]
	
	local resName = getResourceName(res)
	
	if(not g_Widgets[resName]) then
		g_WidgetsCount = g_WidgetsCount + 1
	end
	g_Widgets[resName] = widgetName
	
	local widget = g_Settings.widgets[resName]
	if(widget and g_IsVip) then
		if(widget.visible ~= nil) then
			call(res, 'widgetCtrl', $(wg_show), widget.visible)
		end
		if(widget.pos) then
			call(res, 'widgetCtrl', $(wg_move), widget.pos[1], widget.pos[2])
		end
		if(widget.size) then
			call(res, 'widgetCtrl', $(wg_resize), widget.size[1], widget.size[2])
		end
	end
end

local function VipInit()
	triggerServerEvent('vip.onReady', g_Me)
end

-- Exported function
function openVipPanel()
	if(not g_IsVip) then
		return false
	end
	
	VipToggleSettingsWnd()
	return true
end

function isVip()
	return g_IsVip
end

------------
-- Events --
------------

addEventHandler('onClientResourceStart', resourceRoot, function()
	addEventHandler('vip.onVerified', g_Root, VipOnClientVip)
	addEventHandler('onRafalhAddWidget', g_Root, VipOnAddWidget)
	VipInit()
end)
