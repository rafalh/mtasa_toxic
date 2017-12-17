--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

---------------------
-- Local variables --
---------------------

local g_JoinMsgWnd = false

addEvent('toxic.onThunderEffect', true)
addEvent('toxic.onSetPlayerAlphaReq', true)

local function ShpOnJoinMsgUse(v)
	if(g_JoinMsgWnd) then
		guiBringToFront(g_JoinMsgWnd)
		return
	end
	
	local w, h = 250, 110
	local x, y =(g_ScreenSize[1] - w) / 2,(g_ScreenSize[2] - h) / 2
	g_JoinMsgWnd = guiCreateWindow(x, y, w, h, "Join Message settings", false)
	
	guiCreateLabel(10, 20, 220, 20, "New Join Message:", false, g_JoinMsgWnd)
	local edit = guiCreateEdit(10, 40, 230, 20, v or '', false, g_JoinMsgWnd)
	guiSetProperty(edit, 'MaxTextLength', '128')
	
	showCursor(true)
	
	local btn = guiCreateButton(70, 70, 50, 25, "OK", false, g_JoinMsgWnd)
	addEventHandler('onClientGUIClick', btn, function()
		if(ShpGetInventory('joinmsg')) then
			local msg = guiGetText(edit)
			ShpSetInventory('joinmsg', msg)
			triggerServerInternalEvent($(EV_SET_JOIN_MSG_REQUEST), g_Me, msg)
		end
		destroyElement(getElementParent(source))
		g_JoinMsgWnd = false
		showCursor(false)
	end, false)
	
	local btn = guiCreateButton(130, 70, 50, 25, "Cancel", false, g_JoinMsgWnd)
	addEventHandler('onClientGUIClick', btn, function()
		destroyElement(getElementParent(source))
		g_JoinMsgWnd = false
		showCursor(false)
	end, false)
end

ShpRegisterItem{
	id = 'joinmsg',
	name = "Join Message",
	descr = "Set message, which is displayed when you join.",
	img = 'shop/img/joinmsg.png',
	onUse = ShpOnJoinMsgUse,
	useBtnText = "Change",
	hideInItemsPanel = true,
	dataToCount = function(val) return val and 1 end,
	getAllowedAct = function(val) return not val, true, true end -- buy, sell, use
}

ShpRegisterItem{
	id = 'health100',
	name = "Repair",
	descr = "Repair your vehicle when you want.",
	img = 'shop/img/repair.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'flip',
	name = "Flip",
	descr = "Flips your vehicle.",
	img = 'shop/img/flip.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val)
		local veh = getPedOccupiedVehicle(g_Me)
		if(veh) then
			local rx, ry, rz = getElementRotation(veh)
			--outputChatBox('r: '..rx..' '..ry..' '..rz)
			return true, true, not isPlayerDead(g_Me) and(( rx > 90 and rx < 270) or(ry > 90 and ry < 270)) -- buy, sell, use
		end
		return true, true, false -- buy, sell, use
	end
}

ShpRegisterItem{
	id = 'selfdestr',
	name = "Self-destruction",
	descr = "Make self-destruction and kill all players, which are near to your vehicle!",
	img = 'shop/img/selfdestr.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'mine',
	name = "Mine",
	descr = "Place a mine under your car!",
	img = 'shop/img/mine.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'oil',
	name = "Oil",
	descr = "Spill oil over road!",
	img = 'shop/img/oil.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'beer',
	name = "Beer",
	descr = "Are you angry with whole world? Get drunk!",
	img = 'shop/img/beer.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, true end -- buy, sell, use
}

ShpRegisterItem{
	id = 'invisibility',
	name = "Invisibility",
	descr = "Make your vehicle invisible...",
	img = 'shop/img/ghost.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'godmode30',
	name = "God Mode",
	descr = "Make your vehicle indestructible for 60 seconds!",
	img = 'shop/img/godmode.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'thunder',
	name = "Thunder",
	descr = "Attack nearest player with a thunder.",
	img = 'shop/img/thunder.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'smoke',
	name = "Smoke",
	descr = "Smoke behind your vehicle for 15 seconds.",
	img = 'shop/img/smoke.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end -- buy, sell, use
}

ShpRegisterItem{
	id = 'spikestrip',
	name = "Spike Strip",
	descr = "Punctur tires of your enemies vehicles.",
	img = 'shop/img/spikestrip.png',
	dataToCount = function(val) return val > 0 and val end,
	getAllowedAct = function(val) return true, true, not isPlayerDead(g_Me) end, -- buy, sell, use
	onUse = function(val)
		-- Get position of ground under vehicle
		local veh = getPedOccupiedVehicle(g_Me)
		local x, y, z = getElementPosition(veh)
		z = getGroundPosition(x, y, z) + 0.1
		
		-- Build quaternion from vehicle matrix
		local mat = getElementMatrix(veh)
		local q = Quaternion.fromMatrix(mat)
		
		-- Rotate 90 degrees around Up vector
		q = Quaternion.fromRot(Vector3(unpack(mat[3])), math.pi/2) * q
		local rx, ry, rz = q:toEuler()
		rx, ry, rz = math.deg(rx), math.deg(ry), math.deg(rz)
		
		-- Create spike-strip
		RPC('ShpSpikeStrip', x, y, z, rx, ry, rz, mat):exec()
	end
}

ShpRegisterItem{
	id = 'nextmap',
	name = "Next map",
	descr = "Add your favourite map to queue.",
	img = 'shop/img/nextmap.png',
	getAllowedAct = function(v) return true, false, false end, -- buy, sell, use
	onBuy = function()
		MlstDisplay("Choose the next map to buy", "Buy map", function(res_name)
			if(res_name) then
				triggerServerEvent('toxic.onBuyNextMapReq', g_Me, res_name)
			end
		end)
	end,
}

ShpRegisterItem{
	id = 'vip1w',
	name = "VIP rank",
	noDiscount = true,
	descr = function()
		return MuiGetMsg("VIP rank activation for %u days."):format(touint(Shop.Config.get('vip1w').params.days, 7))
	end,
	img = 'vip/enabled.png',
	getAllowedAct = function(v) return true, false, false end -- buy, sell, use
}

--------------------------------
-- Local function definitions --
--------------------------------

local g_DrunkEffectLastAngle = 0
local g_DrunkEffectStartTime = 0
local g_DrunkEffectTimer = false

local function ShpUpdateDrunkEffect()
	local veh = getCameraTarget()
	if(veh and getElementType(veh) == 'vehicle') then
		local a = (getTickCount() - g_DrunkEffectStartTime) / 1000
		local x, y, z = getVehicleGravity(veh)
		--outputChatBox('g: '..x..' '..y..' '..z)
		setVehicleGravity(veh, x - math.sin(g_DrunkEffectLastAngle) / 3 + math.sin(a) / 3, y - math.cos(g_DrunkEffectLastAngle) / 3 + math.cos(a) / 3, z)
		g_DrunkEffectLastAngle = a
	end
end

local function ShpDrunkEffect()
	if(g_DrunkEffectTimer) then
		resetTimer(g_DrunkEffectTimer)
	else
		g_DrunkEffectStartTime = getTickCount()
		g_DrunkEffectLastAngle = 0
		local veh = getCameraTarget()
		if(veh and getElementType(veh) == 'vehicle') then
			local x, y, z = getVehicleGravity(veh)
			--outputChatBox('g: '..x..' '..y..' '..z)
			setVehicleGravity(veh, x + math.sin(0) / 3, y + math.cos(0) / 3, z)
		end
		addEventHandler('onClientPreRender', g_Root, ShpUpdateDrunkEffect, false)
		
		local seconds = Shop.Config.get('beer').params.seconds or 20
		g_DrunkEffectTimer = setTimer(function()
			g_DrunkEffectTimer = false
			removeEventHandler('onClientPreRender', g_Root, ShpUpdateDrunkEffect)
			local veh = getCameraTarget()
			if(veh and getElementType(veh) == 'vehicle') then
				local x, y, z = getVehicleGravity(veh)
				setVehicleGravity(veh, x - math.sin(g_DrunkEffectLastAngle) / 3, y - math.cos(g_DrunkEffectLastAngle) / 3, z)
			end
		end, seconds * 1000, 1, target)
	end
end

local ShpThunderEffect = {}
ShpThunderEffect.active = false

function ShpThunderEffect.onRender()
	if(getTickCount() - ShpThunderEffect.ticks > 5000) then
		removeEventHandler('onClientRender', g_Root, ShpThunderEffect.onRender)
		ShpThunderEffect.active = false
	end
	
	local src = getPedOccupiedVehicle(ShpThunderEffect.source) or ShpThunderEffect.source
	local dst = getPedOccupiedVehicle(ShpThunderEffect.target) or ShpThunderEffect.target
	local vecBegin = Vector3(getElementPosition(src))
	local vecEnd = Vector3(getElementPosition(dst))
	
	local vecDir = vecEnd - vecBegin
	vecDir = vecDir * 0.1
	local vec = vecBegin
	for i = 1, 9, 1 do
		local vec2 = vecBegin + vecDir * i
		for j = 1, 3, 1 do
			vec2[j] = vec2[j] + (math.random()-0.5)*0.75
		end
		dxDrawLine3D(vec[1], vec[2], vec[3], vec2[1], vec2[2], vec2[3], 0x60FFFFFF, 5)
		dxDrawLine3D(vec[1], vec[2], vec[3], vec2[1], vec2[2], vec2[3], 0xA0FFFFFF, 3)
		vec = vec2
	end
	local vec2 = vecEnd
	dxDrawLine3D(vec[1], vec[2], vec[3], vec2[1], vec2[2], vec2[3], 0x60FFFFFF, 5)
	dxDrawLine3D(vec[1], vec[2], vec[3], vec2[1], vec2[2], vec2[3], 0xA0FFFFFF, 3)
end

function ShpThunderEffect.start(target)
	ShpThunderEffect.source = source
	ShpThunderEffect.target = target
	ShpThunderEffect.ticks = getTickCount()
	if(not ShpThunderEffect.active) then
		addEventHandler('onClientRender', g_Root, ShpThunderEffect.onRender)
	end
end

local function ShpSetPlayerAlpha(value)
	setElementAlpha(source, value)
	for i, el in ipairs(getAttachedElements(source)) do
		setElementAlpha(el, value)
		if(getElementType(el) == 'blip') then
			--Debug.info('blip')
			setBlipColor(el, 0, 0, 0, 0)
		end
	end
	
	local veh = getPedOccupiedVehicle(source)
	if(veh) then
		setElementAlpha(veh, value)
		for i, el in ipairs(getAttachedElements(veh)) do
			setElementAlpha(el, value)
			if(getElementType(el) == 'blip') then
				Debug.warn('blip2')
				setBlipColor(el, 0, 0, 0, 0)
			end
		end
		
		setVehicleOverrideLights(veh, 1)
	end
end

addInitFunc(function()
	addInternalEventHandler($(EV_CLIENT_DRUNK_EFFECT), ShpDrunkEffect)
	addEventHandler('toxic.onThunderEffect', g_Root, ShpThunderEffect.start)
	addEventHandler('toxic.onSetPlayerAlphaReq', g_Root, ShpSetPlayerAlpha)
end)
