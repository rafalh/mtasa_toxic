--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

g_ShopItems = {} -- name = { title, cost, description, onUse handler (if false this item can be only used), onInitButtons }

addEvent ( "onThunderEffect", true )
addEvent ( "onSetPlayerAlphaReq", true )
addEvent("rafalh_onBuyNextMap", true)

local g_JoinMsgWnd = false

local function ShpOnJoinMsgUse ( v )
	if ( g_JoinMsgWnd ) then
		guiBringToFront ( g_JoinMsgWnd )
		return
	end
	
	local w, h = 250, 110
	local x, y = ( g_ScreenSize[1] - w ) / 2, ( g_ScreenSize[2] - h ) / 2
	g_JoinMsgWnd = guiCreateWindow ( x, y, w, h, "Join Message settings", false )
	
	guiCreateLabel ( 10, 20, 220, 20, "New Join Message:", false, g_JoinMsgWnd )
	local edit = guiCreateEdit ( 10, 40, 230, 20, v or "", false, g_JoinMsgWnd )
	guiSetProperty ( edit, "MaxTextLength", "128" )
	
	guiSetInputEnabled ( true )
	
	local btn = guiCreateButton ( 70, 70, 50, 25, "OK", false, g_JoinMsgWnd )
	addEventHandler ( "onClientGUIClick", btn, function ()
		if ( ShpGetInventory ( "joinmsg" ) ) then
			local msg = guiGetText ( edit )
			ShpSetInventory ( "joinmsg", msg )
			triggerServerInternalEvent ( $(EV_SET_JOIN_MSG_REQUEST), g_Me, msg )
		end
		destroyElement ( getElementParent ( source ) )
		g_JoinMsgWnd = false
		guiSetInputEnabled ( false )
	end, false )
	
	local btn = guiCreateButton ( 130, 70, 50, 25, "Cancel", false, g_JoinMsgWnd )
	addEventHandler ( "onClientGUIClick", btn, function ()
		destroyElement ( getElementParent ( source ) )
		g_JoinMsgWnd = false
		guiSetInputEnabled ( false )
	end, false )
end

g_ShopItems.joinmsg = {
	name = "Join Message",
	cost = 20000,
	descr = "Set message, which is displayed when you join.",
	img = "shop/img/joinmsg.png",
	onUse = ShpOnJoinMsgUse,
	dataToCount = function ( val ) return val and 1 end,
	getAllowedAct = function ( val ) return not val, true, true end -- buy, sell, use
}

g_ShopItems.health100 = {
	name = "Repair",
	cost = 100000,
	descr = "Repair your vehicle when you want.",
	img = "shop/img/repair.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.flip = {
	name = "Flip",
	cost = 50000,
	descr = "Flips your vehicle.",
	img = "shop/img/flip.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val )
		local veh = getPedOccupiedVehicle ( g_Me )
		if ( veh ) then
			local rx, ry, rz = getElementRotation ( veh )
			--outputChatBox ( "r: "..rx.." "..ry.." "..rz )
			return true, true, not isPlayerDead ( g_Me ) and ( ( rx > 90 and rx < 270 ) or ( ry > 90 and ry < 270 ) ) -- buy, sell, use
		end
		return true, true, false -- buy, sell, use
	end
}

g_ShopItems.selfdestr = {
	name = "Self-destruction",
	cost = 500000,
	descr = "Make self-destruciton and kill all players, which are near to your vehicle!",
	img = "shop/img/selfdestr.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.mine = {
	name = "Mine",
	cost = 200000,
	descr = "Place a mine under your car!",
	img = "shop/img/mine.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.oil = {
	name = "Oil",
	cost = 100000,
	descr = "Spill oli over road!",
	img = "shop/img/oil.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.beer = {
	name = "Beer",
	cost = 2,
	descr = "Are you angry with whole world? Get drunk!",
	img = "shop/img/beer.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, true end -- buy, sell, use
}

g_ShopItems.invisibility = {
	name = "Invisibility",
	cost = 300000,
	descr = "Make your vehicle invisible...",
	img = "shop/img/ghost.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.godmode30 = {
	name = "Godmode",
	cost = 300000,
	descr = "Make your vehicle indestructible for 60 seconds!",
	img = "shop/img/godmode.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.thunder = {
	name = "Thunder",
	cost = 200000,
	descr = "Attack near player for few seconds",
	img = "shop/img/thunder.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.smoke = {
	name = "Smoke",
	cost = 100000,
	descr = "Smoke behind your vehicle for 15 seconds.",
	img = "shop/img/smoke.png",
	dataToCount = function ( val ) return val > 0 and val end,
	getAllowedAct = function ( val ) return true, true, not isPlayerDead ( g_Me ) end -- buy, sell, use
}

g_ShopItems.nextmap = {
	name = "Next map",
	cost = 20000,
	descr = "Add your favorite map to queue.",
	img = "shop/img/nextmap.png",
	getAllowedAct = function ( v ) return true, false, false end, -- buy, sell, use
	onBuy = function ()
		MlstDisplay ( "Choose the next map to buy", "Buy map", function ( res_name )
			if ( res_name ) then
				triggerServerEvent ( "onBuyNextMapReq", g_Me, res_name )
			end
		end )
	end
}

g_ShopItems.vip1w = {
	name = "VIP rank",
	cost = 2500000,
	descr = "VIP rank activation for 1 week.",
	img = "img/vip/enabled.png",
	getAllowedAct = function ( v ) return true, false, false end -- buy, sell, use
}

--------------------------------
-- Local function definitions --
--------------------------------

local g_DrunkEffectLastAngle = 0
local g_DrunkEffectStartTime = 0
local g_DrunkEffectTimer = false

local function ShpUpdateDrunkEffect ()
	local veh = getCameraTarget ()
	if ( veh and getElementType ( veh ) == "vehicle" ) then
		local a = ( getTickCount () - g_DrunkEffectStartTime ) / 1000
		local x, y, z = getVehicleGravity ( veh )
		--outputChatBox ( "g: "..x.." "..y.." "..z )
		setVehicleGravity ( veh, x - math.sin ( g_DrunkEffectLastAngle ) / 3 + math.sin ( a ) / 3, y - math.cos ( g_DrunkEffectLastAngle ) / 3 + math.cos ( a ) / 3, z )
		g_DrunkEffectLastAngle = a
	end
end

local function ShpDrunkEffect ()
	if ( g_DrunkEffectTimer ) then
		resetTimer ( g_DrunkEffectTimer )
	else
		g_DrunkEffectStartTime = getTickCount ()
		g_DrunkEffectLastAngle = 0
		local veh = getCameraTarget ()
		if ( veh and getElementType ( veh ) == "vehicle" ) then
			local x, y, z = getVehicleGravity ( veh )
			--outputChatBox ( "g: "..x.." "..y.." "..z )
			setVehicleGravity ( veh, x + math.sin ( 0 ) / 3, y + math.cos ( 0 ) / 3, z )
		end
		addEventHandler ( "onClientPreRender", g_Root, ShpUpdateDrunkEffect, false )
		
		g_DrunkEffectTimer = setTimer ( function ()
			g_DrunkEffectTimer = false
			removeEventHandler ( "onClientPreRender", g_Root, ShpUpdateDrunkEffect )
			local veh = getCameraTarget ()
			if ( veh and getElementType ( veh ) == "vehicle" ) then
				local x, y, z = getVehicleGravity ( veh )
				setVehicleGravity ( veh, x - math.sin ( g_DrunkEffectLastAngle ) / 3, y - math.cos ( g_DrunkEffectLastAngle ) / 3, z )
			end
		end, 20000, 1, target )
	end
end

local g_ThunderEffectSource, g_ThunderEffectTarget, g_ThunderEffectStart

local function VecNeg ( vec )
	return { -vec[1], -vec[2], -vec[3] }
end

local function VecAdd ( vec1, vec2 )
	return { vec1[1] + vec2[1], vec1[2] + vec2[2], vec1[3] + vec2[3] }
end

local function VecSub ( vec1, vec2 )
	return VecAdd(vec1, VecNeg (vec2))
end

local function VecMult ( vec, a )
	return {vec[1] * a, vec[2] * a, vec[3] * a}
end

local function ShpRenderThunderEffect ()
	if ( getTickCount () - g_ThunderEffectStart > 5000 ) then
		removeEventHandler ( "onClientRender", g_Root, ShpRenderThunderEffect )
	end
	
	local src = getPedOccupiedVehicle ( g_ThunderEffectSource ) or g_ThunderEffectSource
	local dst = getPedOccupiedVehicle ( g_ThunderEffectTarget ) or g_ThunderEffectTarget
	local vecBegin = { getElementPosition(src) }
	local vecEnd = { getElementPosition(dst) }
	
	local vecDir = VecSub(vecEnd, vecBegin)
	vecDir = VecMult(vecDir, 1/10)
	local vec = vecBegin
	for i = 1, 9, 1 do
		local vec2 = VecAdd(vecBegin, VecMult(vecDir, i))
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

local function ShpThunderEffect ( target )
	g_ThunderEffectSource = source
	g_ThunderEffectTarget = target
	g_ThunderEffectStart = getTickCount ()
	addEventHandler ( "onClientRender", g_Root, ShpRenderThunderEffect )
end

local function ShpSetPlayerAlpha ( value )
	setElementAlpha ( source, value )
	for i, el in ipairs ( getAttachedElements ( source ) ) do
		setElementAlpha ( el, value )
		if ( getElementType ( el ) =="blip" ) then
			--outputDebugString ( "blip", 3 )
			setBlipColor ( el, 0, 0, 0, 0 )
		end
	end
	
	local veh = getPedOccupiedVehicle ( source )
	if ( veh ) then
		setElementAlpha ( veh, value )
		for i, el in ipairs ( getAttachedElements ( veh ) ) do
			setElementAlpha ( el, value )
			if ( getElementType ( el ) =="blip" ) then
				outputDebugString ( "blip2", 2 )
				setBlipColor ( el, 0, 0, 0, 0 )
			end
		end
		
		setVehicleOverrideLights ( veh, 1 )
	end
end

------------
-- Events --
------------

addInternalEventHandler ( $(EV_CLIENT_DRUNK_EFFECT), ShpDrunkEffect )
addEventHandler ( "onThunderEffect", g_Root, ShpThunderEffect )
addEventHandler ( "onSetPlayerAlphaReq", g_Root, ShpSetPlayerAlpha )
addEventHandler("rafalh_onBuyNextMap", g_ResRoot, g_ShopItems.nextmap.onBuy)
