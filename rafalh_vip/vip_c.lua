-- Includes
#include '../include/widgets.lua'

-- Global variables
g_Root = getRootElement()
g_Me = getLocalPlayer()
g_Widgets = {}
g_WidgetsCount = 0
g_Settings = {
	widgets = {},
	ignored = {},
	neon = false, neon_clr = '#0080FF',
	vehcolor = false, vehcolor1 = '#000000', vehcolor2 = '#000000',
	vehrainbow = false, vehrainbow_speed = 1,
	vehlicolor = false, vehlicolor_clr = '#C0C0FF',
	driver = false, driver_id = 0,
	clouds = true,
	blur = false,
	forcevehlion = false,
	paintjob = 0,
	autopilot = false,
	mynametag = false,
	avatar = '',
	vehupgrades = {},
}
g_IsVip, g_VipEnd = false, false
local g_RainbowPlayers = {}
local g_RainbowPlayersCount = 0

-------------------
-- Custom events --
-------------------

addEvent('vip.onSettings', true)
addEvent('vip.onReady', true)
addEvent('vip.onVerified', true)
addEvent('onRafalhAddWidget')
addEvent('onRafalhGetWidgets')
addEvent('vip.onStatus')
addEvent('vip.onPlayerInfo', true)

--------------------------------
-- Local function definitions --
--------------------------------

function VipLoadSettings()
	-- Mark settings as loaded even if file does not exist
	g_SettingsLoaded = true
	
	local node = xmlLoadFile('settings.xml')
	if(not node) then return end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local name = xmlNodeGetName(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		local val = xmlNodeGetValue(subnode)
		
		if(name == 'neon') then
			g_Settings.neon = (val == 'true')
			g_Settings.neon_clr = attr.clr and getColorFromString(attr.clr) and attr.clr or '#0080FF'
		elseif(name == 'vehcolor') then
			g_Settings.vehcolor = (val == 'true')
			local clr1 = xmlNodeGetAttribute(subnode, 'clr1')
			local clr2 = xmlNodeGetAttribute(subnode, 'clr2')
			g_Settings.vehcolor1 = attr.clr1 and getColorFromString(attr.clr1) and attr.clr1 or '#000000'
			g_Settings.vehcolor2 = attr.clr2 and getColorFromString(attr.clr2) and attr.clr2 or '#000000'
		elseif(name == 'vehrainbow') then
			g_Settings.vehrainbow = (val == 'true')
			g_Settings.vehrainbow_speed = math.max(tonumber(attr.speed) or 3, 3)
		elseif(name == 'vehlicolor') then
			g_Settings.vehlicolor = (val == 'true')
			g_Settings.vehlicolor_clr = attr.clr and getColorFromString(attr.clr) and attr.clr or '#C0C0FF'
		elseif(name == 'driver') then
			g_Settings.driver = (val == 'true')
			g_Settings.driver_id = tonumber(attr.id) or 0
		elseif(name == 'clouds') then
			g_Settings.clouds = (val == 'true')
		elseif(name == 'blur') then
			g_Settings.blur = (val == 'true')
		elseif(name == 'forcevehlion') then
			g_Settings.forcevehlion = (val == 'true')
		elseif(name == 'paintjob') then
			g_Settings.paintjob = tonumber(val) or 0
		elseif(name == 'autopilot') then
			g_Settings.autopilot = (val == 'true')
		elseif(name == 'mynametag') then
			g_Settings.mynametag = (val == 'true')
		elseif(name == 'avatar') then
			g_Settings.avatar = val
		elseif(name == 'vehupgrade') then
			local upg = tonumber(val)
			if(upg) then
				local slot = VipGetVehicleUpgradeSlot(upg)
				g_Settings.vehupgrades[slot] = upg
			end
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

function VipSaveSettings()
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
	
	subnode = xmlCreateChild(node, 'vehrainbow')
	if(subnode) then
		xmlNodeSetValue(subnode, tostring(g_Settings.vehrainbow))
		xmlNodeSetAttribute(subnode, 'speed', g_Settings.vehrainbow_speed)
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
	
	for slot, upg in pairs(g_Settings.vehupgrades) do
		subnode = xmlCreateChild(node, 'vehupgrade')
		if(subnode) then
			xmlNodeSetValue(subnode, tostring(upg))
		end
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

function VipActivateSettings()
	setBlurLevel(( g_Settings.blur and 36) or 0)
	setCloudsEnabled(g_Settings.clouds)
	setElementData(g_Me, 'my_nametag_visible', g_Settings.mynametag, false)
end

local function VipUpdateRainbowPlayers()
	local now = getTickCount()
	for player, info in pairs(g_RainbowPlayers) do
		local veh = getPedOccupiedVehicle(player)
		if(veh) then
			if(not info.ticks or now - info.ticks > info.speed*1000) then
				info.r1, info.g1, info.b1 = getVehicleColor(veh, true)
				info.r2, info.g2, info.b2 = math.random(0, 255), math.random(0, 255), math.random(0, 255)
				info.ticks = now
			end
			
			local progress = (now - info.ticks) / (info.speed*1000)
			local r = info.r2 * progress + info.r1 * (1 - progress)
			local g = info.g2 * progress + info.g1 * (1 - progress)
			local b = info.b2 * progress + info.b1 * (1 - progress)
			setVehicleColor(veh, r, g, b)
		end
	end
end

local function VipSetRainbow(player, speed)
	--outputDebugString('VipSetRainbow '..getPlayerName(player)..' '..tostring(speed), 3)
	
	if(not g_RainbowPlayers[player]) then
		if(not speed) then return end
		g_RainbowPlayers[player] = {
			ticks = false,
			speed = speed}
		g_RainbowPlayersCount = g_RainbowPlayersCount + 1
		if(g_RainbowPlayersCount == 1) then
			addEventHandler('onClientPreRender', root, VipUpdateRainbowPlayers)
		end
	elseif(not speed) then
		g_RainbowPlayers[player] = nil
		g_RainbowPlayersCount = g_RainbowPlayersCount - 1
		if(g_RainbowPlayersCount == 0) then
			removeEventHandler('onClientPreRender', root, VipUpdateRainbowPlayers)
		end
	else
		g_RainbowPlayers[player].speed = speed
	end
end

local function VipOnPlayerQuit()
	VipSetRainbow(source, false)
end

local function VipOnClientVip(timestamp)
	g_VipEnd = timestamp
	
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

local function VipOnPlayerInfo(player, info)
	VipSetRainbow(player, info.rainbow)
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
	addEventHandler('vip.onVerified', resourceRoot, VipOnClientVip)
	addEventHandler('vip.onPlayerInfo', resourceRoot, VipOnPlayerInfo)
	addEventHandler('onRafalhAddWidget', g_Root, VipOnAddWidget)
	addEventHandler('onClientPlayerQuit', g_Root, VipOnPlayerQuit)
	VipInit()
end)
