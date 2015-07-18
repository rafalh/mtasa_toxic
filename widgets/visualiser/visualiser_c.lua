-- Includes
#include "../../include/widgets.lua"

local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement()
local g_Me = getLocalPlayer()
local g_ScreenSize = {guiGetScreenSize()}
local g_ScreenSizeSqrt = {g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2)}
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}
local g_WidgetName = {"Sound visualiser", pl = "Wizualizer dźwięku"}
local g_Particles
local g_Textures = {}
local g_FindMusicTimer = false

local BANDS = 40
local MIN_SOUND_LEN = 30
local FONT = "arial"
local TEXT_COLOR = tocolor(255, 255, 255)

local function reset()
	-- reset particles data
	g_Particles = {}
	for k = 1, BANDS do
		g_Particles[k] = {}
	end
end

local function render()
	if(not g_Sound) then return end
	
	-- Get 2048 / 2 samples and return BANDS bars (still needs scaling up)
	local fft = getSoundFFTData(g_Sound, 2048, BANDS)
	if(not fft) then
		-- if fft is false it hasn't loaded
		dxDrawText("Stream not loaded yet...", g_Pos[1], g_Pos[2])
		return
	end
	
	-- Get some info about the stream
	local bpm = getSoundBPM(g_Sound) or 0
	local metaTags = getSoundMetaTags(g_Sound)
	local soundPos = getSoundPosition(g_Sound)
	local soundLen = getSoundLength(g_Sound)
	local ticks = getTickCount()
	local seconds = ticks / 1000
	
	-- Determine color
	local r, g, b = 0, 0, 0
	local val = (seconds % 60)/10
	if(val < 1) then
		r = 255 - val*255
		g = 255
	elseif(val < 2) then
		g = 255
		b = (val - 1)*255
	elseif(val < 3) then
		b = 255
		g = 255 - (val - 2)*255
	elseif(val < 4) then
		b = 255
		r = (val - 3)*255
	elseif(val < 5) then
		r = 255
		b = 255 - (val - 4)*255
	else
		r = 255
		g = (val - 5)*255
	end
	
	-- render background
	dxDrawImage(g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], g_Textures.bg, 0, 0, 0, tocolor(r, g, b, 128))
	
	local moveSpeed = (1 * (bpm / 180)) + 1
	local peakWPad = g_Size[1] / (BANDS + 2)
	local peakW = math.min(10, peakWPad)
	local peakOffX = (peakWPad - peakW)/2
	
	-- loop all the bands
	assert(fft[0])
	assert(#fft == BANDS - 1, tostring(#fft))
	for x = 0, BANDS - 1 do
		-- fft contains our precalculated data so just grab it
		local peak = fft[x]
		local i = x + 1

		-- cap it
		peak = math.max(peak, 0)
		peak = math.min(peak, 1)

		-- scale it (sqrt to make low values more visible)
		local peakH = math.sqrt(peak) * g_Size[2]
		
		-- render peak
		local peakX = g_Pos[1] + i * peakWPad + peakOffX
		local peakY = g_Pos[2] + g_Size[2] - peakH
		if (peakH > 0) then
			dxDrawRectangle(peakX, peakY, peakW, peakH, tocolor(r, g, b, 255))
		end
		
		-- render particles
		local particles = g_Particles[i]
		local j = 1
		while(true) do
			local val = particles[j]
			if(not val) then break end
			
			dxDrawRectangle(val.x, val.y, 2, 2, tocolor(r, g, b, val.a))
			
			val.y = val.y - moveSpeed
			val.x = val.x + (math.random()*2 - 1) * moveSpeed
			val.a = val.a - math.random(2, 5)
			
			if(val.a <= 0) then
				table.remove(particles, j)
			else
				j = j + 1
			end
		end
		
		-- spawn new particle
		local timeForParticle = not particles.ticks or (ticks - particles.ticks) >= 200
		local isGoingUp = particles.prev and peak > particles.prev
		if(#particles <= 10 and timeForParticle and isGoingUp) then
			local val = {}
			val.y = peakY
			val.x = peakX + math.random()*peakW
			val.a = 128
			
			table.insert(particles, val)
			particles.ticks = ticks
		end
		
		-- save peak value for future use
		particles.prev = peak
	end
	
	--[[if(not DBG_TICKS or getTickCount() - DBG_TICKS > 1000) then
		for k, v in pairs(metaTags) do
			outputChatBox(tostring(k).." = "..tostring(v))
		end
		DBG_TICKS = getTickCount()
	end]]
	
	local title = metaTags.title or metaTags.stream_title
	local subtitle = metaTags.artist or metaTags.album or metaTags.stream_name
	if(not title) then
		title = subtitle
		subtitle = false
	end
	
	-- render title
	local left, top = g_Pos[1] + 10, g_Pos[2] + 10
	local right, bottom = g_Pos[1] + g_Size[1], g_Pos[2] + math.min(g_Size[2], 40)
	if(soundLen > 0) then
		-- make place for time
		right = right - 90
	end
	dxDrawText(title or "Unknown", left, top, right, bottom, TEXT_COLOR, 2, FONT, "left", "top", true)
	
	-- render subtitle
	if(subtitle) then
		local left, top = g_Pos[1] + 10, g_Pos[2] + 35
		local right, bottom = g_Pos[1] + g_Size[1], g_Pos[2] + g_Size[2]
		dxDrawText(subtitle, left, top, right, bottom, TEXT_COLOR, 1.5, FONT, "left", "top", true)
	end
	
	-- render time
	if(soundLen > 0) then
		local timeStr = ("%d:%02d/%d:%02d"):format(soundPos/60, soundPos%60, soundLen/60, soundLen%60)
		local left, top = g_Pos[1] + g_Size[1] - 90, g_Pos[2] + 10
		local right, bottom = g_Pos[1] + g_Size[1], g_Pos[2] + math.min(g_Size[2], 35)
		dxDrawText(timeStr, left, top, right, bottom, TEXT_COLOR, 1.5, FONT, "left", "top", true)
	end
	
	--dxDrawText("BPM: "..math.floor(bpm), g_Pos[1] + g_Size[1] - 90, g_Pos[2] + 30, 0, 0, tocolor(255, 255, 255, 255 ), 1.5, "arial")
end

local function findMusic(ignored)
	if(not g_Show) then
		g_Sound = false
		return false
	end
	
	local found = false
	local sounds = getElementsByType("sound")
	for i, sound in ipairs(sounds) do
		local len = getSoundLength(sound)
		local vol = getSoundVolume(sound)
		local paused = isSoundPaused(sound)
		if((len > MIN_SOUND_LEN or len == 0) and vol > 0 and not paused and sound ~= ignored) then
			found = sound
			break
		end
	end
	
	if(not g_Sound and found) then
		addEventHandler("onClientRender", g_Root, render)
	elseif(g_Sound and not found) then
		removeEventHandler("onClientRender", g_Root, render)
	end
	
	g_Sound = found
	
	return found and true
end

local function onSoundStream(success, length, name)
	if(not g_Show) then return end
	
	findMusic()
end

local function onElDestroy()
	if(not g_Show) then return end
	
	if(g_Sound == source) then
		findMusic(source)
	end
end

g_WidgetCtrl[$(wg_show)] = function ( b )
	if ( ( g_Show and b ) or ( not g_Show and not b ) ) then return end
	g_Show = b
	if(b) then
		reset()
		
		g_Textures.bg = dxCreateTexture("bg.png")
		
		-- Add event handlers
		addEventHandler("onClientSoundStream", g_Root, onSoundStream)
		addEventHandler("onClientElementDestroy", g_Root, onElDestroy)
		
		-- Find music element
		g_FindMusicTimer = setTimer(findMusic, 1000, 0)
		findMusic()
	else
		if(g_Sound) then
			removeEventHandler("onClientRender", g_Root, render)
			g_Sound = false
		end
		reset()
		
		for id, tex in pairs(g_Textures) do
			destroyElement(tex)
		end
		removeEventHandler("onClientSoundStream", g_Root, onSoundStream)
		removeEventHandler("onClientElementDestroy", g_Root, onElDestroy)
		killTimer(g_FindMusicTimer)
	end
end

g_WidgetCtrl[$(wg_isshown)] = function ()
	return g_Show
end

g_WidgetCtrl[$(wg_move)] = function ( x, y )
	g_Pos = { x, y }
end

g_WidgetCtrl[$(wg_resize)] = function ( w, h )
	g_Size = { w, h }
end

g_WidgetCtrl[$(wg_getsize)] = function ()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function ()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function ()
	g_Size = { g_ScreenSizeSqrt[2]*18, g_ScreenSizeSqrt[2]*6 }
	g_Pos = { g_ScreenSize[1]/2 - g_Size[1]/2, g_ScreenSize[2] - g_Size[2] - 32 }
	g_WidgetCtrl[$(wg_show)] ( false )
end

---------------------------------
-- Global function definitions --
---------------------------------

function widgetCtrl ( op, arg1, arg2 )
	if ( g_WidgetCtrl[op] ) then
		return g_WidgetCtrl[op] ( arg1, arg2 )
	end
end

local function init()
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
	
	-- Set a random seed
	math.randomseed(getTickCount())
end

addEventHandler("onClientResourceStart", g_ResRoot, init)

