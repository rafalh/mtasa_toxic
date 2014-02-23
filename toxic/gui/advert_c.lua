
#include 'include/internal_events.lua'

#local DEBUG = false

local g_Adverts = {}
local g_AdvertIdx = 0
local g_Visible = false

-- Settings
local g_TextColor = tocolor(0, 255, 0)
local g_TextFont = 'bankgothic'
local g_TextScale = math.max(0.5, (g_ScreenSize[2]^0.5) / 54) -- 0.6
local g_BgColor = tocolor(16, 16, 16, 128)
local g_Speed = (g_ScreenSize[1]^0.5)*5 --200
local g_AppearingTime = 500
local g_AdvertInterval = 120000

local function AdvRender()
	local ticks = getTickCount()
	local dt = ticks - g_Visible
	
	local text = g_Adverts[g_AdvertIdx]
	local text_w = dxGetTextWidth(text, g_TextScale, g_TextFont)
	local w, h = g_ScreenSize[1], dxGetFontHeight(g_TextScale, g_TextFont)
	local h_fact = 1
	local visible_time = (w + text_w) / g_Speed * 1000
	
	if(dt > visible_time) then
		g_Visible = false
		removeEventHandler('onClientRender', g_Root, AdvRender)
		return
	elseif(dt < g_AppearingTime) then
		h_fact = dt / g_AppearingTime
	elseif(dt > visible_time - g_AppearingTime) then
		h_fact = (visible_time - dt) / g_AppearingTime
	end
	
	local y = - h * (1 - h_fact)
	local h = h * h_fact
	dxDrawRectangle(0, 0, w, h, g_BgColor, true)
	
	local x = w - dt * g_Speed / 1000
	dxDrawText(text, x, y, x, y, g_TextColor, g_TextScale, g_TextFont, 'left', 'top', false, false, true, true)
end

local function AdvShowNext()
	if(not g_Visible) then
		addEventHandler('onClientRender', g_Root, AdvRender)
	end
	
	g_Visible = getTickCount()
	g_AdvertIdx = g_AdvertIdx + 1
	if ( g_AdvertIdx > #g_Adverts ) then
		g_AdvertIdx = 1
	end
	
	outputConsole(g_Adverts[g_AdvertIdx]:gsub('#%x%x%x%x%x%x', ''))
end

local function AdvInit()
	local node = xmlLoadFile('conf/adverts.xml')
	if(not node) then
		Debug.warn('Failed to load adverts.xml')
		return
	end
	
	local tmp = {}
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		
		local advert = {}
		advert.freq = touint(attr.freq, 1)
		if(attr[Settings.locale]) then
			advert.text = attr[Settings.locale]
		else
			advert.text = xmlNodeGetValue(subnode)
		end
		
		table.insert(tmp, advert)
		i = i + 1
	end
	
	xmlUnloadFile(node)
	
	table.sort(tmp, function(a, b) return a.freq < b.freq end)
	
	for i, advert in ipairs(tmp) do
		for j = 1, advert.freq, 1 do
			table.insert(g_Adverts, math.floor(#g_Adverts * j / advert.freq) + 1, advert.text)
		end
	end
	
	if(#g_Adverts > 0) then
		g_AdvertIdx = math.random(0, #g_Adverts)
		setTimer(AdvShowNext, g_AdvertInterval, 0)
		
#if(DEBUG) then
		AdvShowNext()
#end
		
	end
end

addInternalEventHandler($(EV_CLIENT_INIT), AdvInit)
