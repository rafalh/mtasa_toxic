-- Includes
#include 'include/internal_events.lua'

-- Settings
local USE_RENDER_TARGET = true
local TEXT_COLOR = tocolor(255, 255, 255)
local TEXT_FONT = 'bankgothic'
local TEXT_SCALE = math.max(0.5, (g_ScreenSize[2]^0.5) / 54) -- 0.6
local BG_COLOR = tocolor(16, 16, 16, 255)
local BG_COLOR_EXP = tocolor(64, 128, 255, 255)
local BG_COLOR_LVL = tocolor(48, 48, 48, 255)
local POST_GUI = false
local FONT_H = dxGetFontHeight(TEXT_SCALE, TEXT_FONT)
local WHITE = tocolor(255, 255, 255)

local g_CurrentId = false
local g_EXP = false
local g_Buffer = false

-- EXP
-- 1 - 0
-- 2 - 100
-- 3 - 100+200

function LvlFromExp(exp)
	return math.floor((50+(2500+200*exp)^0.5)/100)
end

function ExpFromLvl(lvl)
	return (100 + (lvl - 1)*100)/2 * (lvl - 1)
end

local function EbRenderBar(x, y, w, h, postGUI)
	local lvl = LvlFromExp(g_EXP)
	local curLvlExp = ExpFromLvl(lvl)
	local nextLvlExp = ExpFromLvl(lvl + 1)
	
	local progress = (g_EXP - curLvlExp) / (nextLvlExp - curLvlExp)
	local wExp = w - 100
	local wExpDone = math.floor(wExp*progress)
	dxDrawRectangle(x, y, x + wExpDone, h, BG_COLOR_EXP, postGUI)
	dxDrawRectangle(x + wExpDone, y, x + wExp - wExpDone, h, BG_COLOR, postGUI)
	dxDrawRectangle(x + wExp, y, x + w - wExp, h, BG_COLOR_LVL, postGUI)
	
	local expText = (g_EXP - curLvlExp)..'/'..(nextLvlExp - curLvlExp)
	dxDrawText(expText, x, y, x + wExp, y + h, TEXT_COLOR, TEXT_SCALE, TEXT_FONT, 'center', 'center', false, false, postGUI)
	
	local text = MuiGetMsg("Level %u"):format(lvl)
	dxDrawText(text, x + wExp, y, x + w, y + h, TEXT_COLOR, TEXT_SCALE, TEXT_FONT, 'center', 'center', false, false, postGUI)
end

local function EbUpdateBuffer()
	local w, h = g_ScreenSize[1], FONT_H
	
	if(not g_Buffer) then
		g_Buffer = dxCreateRenderTarget(w, h, true)
		dxDrawRectangle(0, 0, w, h, tocolor(255, 0, 0))
	end
	
	dxSetRenderTarget(g_Buffer, true)
	dxSetBlendMode('modulate_add')
	EbRenderBar(0, 0, w, h)
	dxSetBlendMode('blend')
	dxSetRenderTarget()
end

local function EbRender()
	local w, h = g_ScreenSize[1], FONT_H
	local x, y = 0, g_ScreenSize[2] - h
	
	local exp = StGet and StGet(g_MyId or g_Me, 'points') or 0
	if(exp ~= g_EXP) then
		g_EXP = exp
		if(USE_RENDER_TARGET) then
			EbUpdateBuffer()
		end
	end
	
	if(g_Buffer) then
		dxSetBlendMode('add')
		dxDrawImage(x, y, w, h, g_Buffer, 0, 0, 0, WHITE, POST_GUI)
		dxSetBlendMode('blend')
	else
		EbRenderBar(x, y, w, h, POST_GUI)
	end
end

local function EbRestore()
	if(USE_RENDER_TARGET) then
		EbUpdateBuffer()
	end
end

local function EbAccountChange()
	StStopSync(g_CurrentId)
	StDeleteIfNotUsed(g_CurrentId)
	g_CurrentId = g_MyId or g_Me
	StStartSync(g_CurrentId)
end

local function EbInit()
	if(not Settings.exp_bar) then return end
	addEventHandler('onClientRender', g_Root, EbRender)
	addEventHandler('onClientRestore', g_Root, EbRestore)
	g_CurrentId = g_MyId or g_Me
	StStartSync(g_CurrentId)
	addEventHandler('main.onAccountChange', resourceRoot, EbAccountChange)
end

addInternalEventHandler($(EV_CLIENT_INIT), EbInit)
