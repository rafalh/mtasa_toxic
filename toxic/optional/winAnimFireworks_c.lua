local FONT = "bankgothic"
local MIN_SCALE = g_ScreenSize[1] / 1200
local MAX_SCALE = g_ScreenSize[1] / 600
local POST_GUI = false
local FADE_MS = 1000
local EXP_MIN_CHILDREN = 30
local EXP_MAX_CHILDREN = 40
local GRAV = 1/80000
local INIT_SPEED_Y = -0.4
local USE_ROCKET_SPEED = false
local ROCKET_LIFE_TIME = 2300
local SPARK_LIFE_TIME = 3000
local RES_FACT = g_ScreenSize[2]/1050
local DEBUG = false

local g_WinnerAnim = false
local g_WinnerAnimStart
local g_Particles = {}
local g_FrameTicks, g_Timer

addEvent("main.onPlayerWinDD", true)
addEvent("onClientMapStopping")

local function Hue_2_RGB ( v1, v2, vH ) -- helper for hslToRgb
    if ( vH < 0 ) then vH = vH + 1 end
    if ( vH > 1 ) then vH = vH - 1 end
    if ( ( 6 * vH ) < 1 ) then return v1 + ( v2 - v1 ) * 6 * vH end
    if ( ( 2 * vH ) < 1 ) then return v2 end
    if ( ( 3 * vH ) < 2 ) then return v1 + ( v2 - v1 ) * ( ( 2 / 3 ) - vH ) * 6 end
    return v1
end

local function hslToRgb ( hue, sat, lum )
	local r, g, b = 0, 0, 0
	
	-- http://www.easyrgb.com/index.php?X=MATH&H=19#text19
	if ( sat == 0 ) then -- HSL from 0 to 1
		r = lum * 255 -- RGB results from 0 to 255
		g = lum * 255
		b = lum * 255
	else
		local var_2
		if ( lum < 0.5 ) then var_2 = lum * ( 1 + sat )
		else                  var_2 = ( lum + sat ) - ( sat * lum ) end
		
		local var_1 = 2 * lum - var_2
		
		r = 255 * Hue_2_RGB ( var_1, var_2, hue + ( 1 / 3 ) ) 
		g = 255 * Hue_2_RGB ( var_1, var_2, hue )
		b = 255 * Hue_2_RGB ( var_1, var_2, hue - ( 1 / 3 ) )
	end
	return r, g, b
end

local function detonateRocket(rocket)
	local c = math.random(EXP_MIN_CHILDREN, EXP_MAX_CHILDREN)
	for i = 1, 3 do
		for j = 0, c do
			local a = (j / c)*math.pi*2 + math.random()*0.1
			local particle = {}
			particle.x = rocket.x
			particle.y = rocket.y
			local speed = (0.03 + i*0.04 + math.random()*0.05) * RES_FACT
			particle.speedX = math.cos(a)*speed
			particle.speedY = math.sin(a)*speed
			if(USE_ROCKET_SPEED) then
				particle.speedX = particle.speedX + rocket.speedX
				particle.speedY = particle.speedY + rocket.speedY
			end
			particle.clr = rocket.clr
			particle.r, particle.g, particle.b = rocket.r, rocket.g, rocket.b
			particle.ticks = getTickCount()
			table.insert(g_Particles, particle)
		end
	end
end

local function launchRocket()
	local particle = {}
	particle.x = g_ScreenSize[1]/2 + math.random(-50, 50)
	particle.y = g_ScreenSize[2]
	particle.speedX = (math.random()-0.5)/3 * RES_FACT
	particle.speedY = (INIT_SPEED_Y-math.random()/10) * RES_FACT
	local r, g, b = hslToRgb(math.random(), 1, 0.5)
	particle.r, particle.g, particle.b = r, g, b
	particle.clr = tocolor(r, g, b)
	particle.ticks = getTickCount()
	particle.rocket = true
	table.insert(g_Particles, particle)
end

local function renderWinnerAnim()
	local ticks = getTickCount()
	local dt = ticks - g_WinnerAnimStart
	
	--local bgClr = tocolor(0, 0, 0, math.min(dt/4, (30000-dt)/4, 128))
	--dxDrawRectangle(0, 0, g_ScreenSize[1], g_ScreenSize[2], bgClr)
	
	local r, g, b = hslToRgb((dt % 10000)/10000, 1, 0.5)
	local a = math.min(dt/FADE_MS*255, 255)
	local clr = tocolor(r, g, b, a)
	local shadowClr = tocolor(0, 0, 0, a/2)
	local scaleFact = 1 - 2000/(2000+dt)
	local scale = MAX_SCALE*scaleFact + MIN_SCALE*(1-scaleFact)
	
	local playerName = getPlayerName(g_WinnerAnim):gsub("#%x%x%x%x%x%x", "")
	local text = MuiGetMsg("%s is the winner!"):format(playerName)
	dxDrawText(text, scale/2, scale/2, g_ScreenSize[1]+scale/2, g_ScreenSize[2]+scale/2, shadowClr, scale, FONT, "center", "center", false, false, POST_GUI, false, true)
	dxDrawText(text, 0, 0, g_ScreenSize[1], g_ScreenSize[2], clr, scale, FONT, "center", "center", false, false, POST_GUI, false, true)
	
	local frameDelta = g_FrameTicks and ticks - g_FrameTicks or 0
	local i = 1
	while(i < #g_Particles) do
		local particle = g_Particles[i]
		particle.x = particle.x + particle.speedX * frameDelta
		particle.y = particle.y + particle.speedY * frameDelta
		particle.speedY = particle.speedY + frameDelta*GRAV*RES_FACT
		
		local lifeTime = particle.rocket and ROCKET_LIFE_TIME or SPARK_LIFE_TIME
		local dt = ticks - particle.ticks
		if(dt > lifeTime) then
			table.remove(g_Particles, i)
			i = i - 1
			if(particle.rocket) then
				detonateRocket(particle)
			end
		end
		
		local a = 255 - math.min((dt > 1000 and (dt-1000)/2000*255 or 0), 255)
		local x = math.max(math.sin(ticks/100 + particle.x + particle.y)*32, 0)
		local r = math.min(particle.r + x, 255)
		local g = math.min(particle.g + x, 255)
		local b = math.min(particle.b + x, 255)
		local clr = tocolor(r, g, b, a)
		--dxDrawRectangle(particle.x - 2, particle.y - 2, 4, 4, clr, POST_GUI)
		dxDrawImage(particle.x - 4, particle.y - 4, 8, 8, "img/light.png", 0, 0, 0, clr, POST_GUI)
		i = i + 1
	end
	g_FrameTicks = ticks
end

local function startWinnerAnim()
	if(g_WinnerAnim or not g_LocalSettings.winAnim) then return end
	
	g_WinnerAnimStart = getTickCount()
	g_WinnerAnim = source
	g_FrameTicks = g_WinnerAnimStart
	launchRocket()
	g_Timer = setTimer(launchRocket, 1000, 0)
	addEventHandler("onClientRender", g_Root, renderWinnerAnim)
end

local function stopWinnerAnim()
	if(g_WinnerAnim) then
		removeEventHandler("onClientRender", g_Root, renderWinnerAnim)
		killTimer(g_Timer)
		g_Particles = {}
		g_WinnerAnim = false
	end
end

local function onPlayerQuit()
	if(g_WinnerAnim == source) then
		stopWinnerAnim()
	end
end

local function init()
	math.randomseed(getTickCount())
	
	if(DEBUG) then
		source = g_Me
		startWinnerAnim()
	end
end

addEventHandler("main.onPlayerWinDD", g_Root, startWinnerAnim)
addEventHandler("onClientMapStopping", g_Root, stopWinnerAnim)
addEventHandler("onClientPlayerQuit", g_Root, onPlayerQuit)
addEventHandler("onClientResourceStart", g_ResRoot, init)
