----------------------
-- global variables --
----------------------

local g_StartTime = false
local DELAY_TIME = 3000
local FADE_TIME = 500
local SHOW_TIME = 6000
local g_Root = getRootElement()
local g_ScrW, g_ScrH = guiGetScreenSize()
local g_Size = {420, 120}
local g_Pos = {(g_ScrW - g_Size[1]) / 2, (g_ScrH - g_Size[2]) / 2}

--------------------------
-- function definitions --
--------------------------

local function VipRenderBanner()
	local t = getTickCount() - g_StartTime
	local a = 0
	if(t < FADE_TIME) then
		a = t / FADE_TIME
	else
		t = t - FADE_TIME
		if(t < SHOW_TIME) then
			a = 1
		else
			t = t - SHOW_TIME
			if(t < FADE_TIME) then
				a = 1 - t / FADE_TIME
			else
				removeEventHandler("onClientRender", g_Root, VipRenderBanner)
				return
			end
		end
	end
	
	local clr = tocolor(255, 255, 255, a*255)
	dxDrawImage(g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], "img/vip.png", 0, 0, 0, clr)
end

local function VipShowPromoBanner()
	g_StartTime = getTickCount()
	addEventHandler("onClientRender", g_Root, VipRenderBanner)
end

local function VipShowPromoBannerReq()
	--outputDebugString("VipShowPromoBannerReq "..tostring(g_StartTime), 2)
	if(g_StartTime) then return end
	
	g_StartTime = true
	setTimer(VipShowPromoBanner, DELAY_TIME, 1)
end

addEvent("vip.onShowPromoBannerReq", true)
addEventHandler("vip.onShowPromoBannerReq", g_Root, VipShowPromoBannerReq)
