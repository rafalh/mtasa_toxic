-- Includes
#include "include/internal_events.lua"

-- Settings
local TEXT_COLOR = tocolor(255, 255, 255)
local TEXT_FONT = 'bankgothic'
local TEXT_SCALE = math.max(0.5, (g_ScreenSize[2]^0.5) / 54) -- 0.6
local BG_COLOR = tocolor(16, 16, 16, 255)
local BG_COLOR_EXP = tocolor(64, 128, 255, 255)
local BG_COLOR_LVL = tocolor(48, 48, 48, 255)
local POST_GUI = true
local FONT_H = dxGetFontHeight(TEXT_SCALE, TEXT_FONT)

local g_CurrentId = false

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

local function EbRender()
	local w, h = g_ScreenSize[1], FONT_H
	local y = g_ScreenSize[2] - h
	
	local exp = StGet and StGet(g_MyId or g_Me, 'points') or 0
	local lvl = LvlFromExp(exp)
	local curLvlExp = ExpFromLvl(lvl)
	local nextLvlExp = ExpFromLvl(lvl + 1)
	
	local progress = (exp - curLvlExp) / (nextLvlExp - curLvlExp)
	local wExp = w - 100
	local wExpDone = math.floor(wExp*progress)
	dxDrawRectangle(0, y, wExpDone, h, BG_COLOR_EXP, POST_GUI)
	dxDrawRectangle(wExpDone, y, wExp - wExpDone, h, BG_COLOR, POST_GUI)
	dxDrawRectangle(wExp, y, w - wExp, h, BG_COLOR_LVL, POST_GUI)
	
	local expText = (exp - curLvlExp)..'/'..(nextLvlExp - curLvlExp)
	dxDrawText(expText, 0, y, wExp, y+h, TEXT_COLOR, TEXT_SCALE, TEXT_FONT, 'center', 'center', false, false, POST_GUI)
	
	local text = MuiGetMsg("Level %u"):format(lvl)
	dxDrawText(text, wExp, y, w, y+h, TEXT_COLOR, TEXT_SCALE, TEXT_FONT, 'center', 'center', false, false, POST_GUI)
end

local function EbAccountChange()
	StStopSync(g_CurrentId)
	StDeleteIfNotUsed(g_CurrentId)
	g_CurrentId = g_MyId or g_Me
	StStartSync(g_CurrentId)
end

local function EbInit()
	addEventHandler('onClientRender', g_Root, EbRender)
	g_CurrentId = g_MyId or g_Me
	StStartSync(g_CurrentId)
	addEventHandler('main.onAccountChange', resourceRoot, EbAccountChange)
end

addInternalEventHandler($(EV_CLIENT_INIT), EbInit)

