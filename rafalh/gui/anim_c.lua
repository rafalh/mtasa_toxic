local g_WndData = {}
local g_WndCount = 0

local GaUpdate
local GaOnElementDestroy

local function GaRemoveWnd(wnd)
	if(not g_WndData[wnd]) then return end
	
	g_WndData[wnd] = nil
	removeEventHandler("onClientElementDestroy", wnd, GaOnElementDestroy)
	
	g_WndCount = g_WndCount - 1
	if (g_WndCount <= 0) then
		removeEventHandler("onClientPreRender", g_Root, GaUpdate)
	end
end

local function GaRemoveAnimator(wnd, name)
	local data = g_WndData[wnd]
	if(not data[name]) then return end
	
	data[name] = nil
	data.c = data.c - 1
	
	if(data.c <= 0) then
		GaRemoveWnd(wnd)
	end
end

GaUpdate = function ( dt )
	for wnd, data in pairs ( g_WndData ) do
		local fade = data.fade
		if(fade) then
			fade.t1 = math.min ( fade.t1 + dt, fade.t2 )
			local a = (fade.t1 / fade.t2) * fade.a2 + ((fade.t2 - fade.t1) / fade.t2) * fade.a1
			guiSetAlpha(wnd, a)
			if(a == fade.a2 and a <= 0) then
				guiSetVisible(wnd, false)
			end
			
			if(fade.t1 == fade.t2) then
				GaRemoveAnimator(wnd, "fade")
			end
		end
	end
end

GaOnElementDestroy = function()
	GaRemoveWnd(source)
end

local function GaFade(wnd, delay, targetAlpha)
	local data = g_WndData[wnd]
	
	local a = guiGetVisible(wnd) and guiGetAlpha(wnd) or 0
	if(a == targetAlpha) then
		GaRemoveAnimator(wnd, "fade")
		if(targetAlpha == 0) then
			guiSetVisible(wnd, false)
		end
		return
	end
	
	if(not g_WndData[wnd]) then
		if(g_WndCount == 0) then
			addEventHandler("onClientPreRender", g_Root, GaUpdate, false)
		end
		g_WndCount = g_WndCount + 1
		data = {c = 0}
		g_WndData[wnd] = data
		addEventHandler("onClientElementDestroy", wnd, GaOnElementDestroy, false)
	end
	
	guiSetVisible(wnd, true)
	guiSetAlpha(wnd, a)
	if(not data.fade) then
		data.c = data.c + 1
	end
	data.fade = {t1 = 0, t2 = delay, a1 = a, a2 = targetAlpha}
end

function GaFadeIn(wnd, delay, targetAlpha)
	if(not targetAlpha) then
		targetAlpha = 1
	end
	--outputDebugString("GaFadeIn "..g_WndCount.." "..guiGetAlpha ( wnd ).."-"..targetAlpha, 3)
	GaFade(wnd, delay, targetAlpha)
end

function GaFadeOut(wnd, delay, targetAlpha)
	if(not targetAlpha) then
		targetAlpha = 0
	end
	--outputDebugString("GaFadeOut "..g_WndCount.." "..guiGetAlpha(wnd).."-"..targetAlpha, 3)
	GaFade(wnd, delay, targetAlpha)
end
