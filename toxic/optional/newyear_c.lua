local g_Particles = {}
local g_FrameTicks = 0
local g_StartTicks

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
	local c = math.random(8, 10)
	for j = 0, c do
		local a = (j / c)*math.pi*2
		local particle = {}
		particle.x = rocket.x
		particle.y = rocket.y
		particle.speedX = rocket.speedX + math.cos(a)/10
		particle.speedY = rocket.speedY + math.sin(a)/10
		particle.clr = rocket.clr
		particle.ticks = getTickCount()
		table.insert(g_Particles, particle)
	end
end

local function launchRocket()
	local particle = {}
	particle.x = g_ScreenSize[1]/2 + math.random(-50, 50)
	particle.y = g_ScreenSize[2]
	particle.speedX = (math.random()-0.5)/5
	particle.speedY = -0.4-math.random()/10
	local r, g, b = hslToRgb(math.random(), 1, 0.5)
	particle.clr = tocolor(r, g, b)
	particle.ticks = getTickCount()
	particle.rocket = true
	table.insert(g_Particles, particle)
end

local function renderAnim()
	local ticks = getTickCount()
	local dt = ticks - g_StartTicks
	
	if(dt >= 30000) then
		removeEventHandler('onClientRender', root, renderAnim)
	end
	
	local bgClr = tocolor(0, 0, 0, math.min(dt/4, (30000-dt)/4, 128))
	dxDrawRectangle(0, 0, g_ScreenSize[1], g_ScreenSize[2], bgClr)
	
	local r, g, b = hslToRgb((dt % 10000)/10000, 1, 0.5)
	local clr = tocolor(r, g, b)
	local shadowClr = tocolor(0, 0, 0, 128)
	local scale = math.min(4 + dt/2000, 5.5)
	local tm = getRealTime()
	local text = 'HAPPY NEW YEAR\n'..tostring(1900+tm.year)
	dxDrawText(text, scale/2, scale/2, g_ScreenSize[1]+scale/2, g_ScreenSize[2]+scale/2, shadowClr, scale, 'bankgothic', 'center', 'center', false, false, true, false, true)
	dxDrawText(text, 0, 0, g_ScreenSize[1], g_ScreenSize[2], clr, scale, 'bankgothic', 'center', 'center', false, false, true, false, true)
	
	local frameDelta = g_FrameTicks and ticks - g_FrameTicks or 0
	local i = 1
	while(i < #g_Particles) do
		local particle = g_Particles[i]
		particle.x = particle.x + particle.speedX * frameDelta
		particle.y = particle.y + particle.speedY * frameDelta
		particle.speedY = particle.speedY + frameDelta/8000
		
		local lifeTime = particle.rocket and 3000 or 10000
		if(ticks - particle.ticks > lifeTime) then
			table.remove(g_Particles, i)
			i = i - 1
			if(particle.rocket) then
				detonateRocket(particle)
			end
		end
		dxDrawRectangle(particle.x - 2, particle.y - 2, 4, 4, particle.clr, true)
		i = i + 1
	end
	g_FrameTicks = ticks
end

local function renderCountDown()
	local ticks = getTickCount()
	local dt = ticks - g_StartTicks
	if(dt < 10*1000) then
		local sec = math.floor(dt/1000)
		local dtSec = dt - sec*1000
		local clr = tocolor(255, 255, 0)
		local shadowClr = tocolor(0, 0, 0, 128)
		local scale = dtSec/30
		local text = tostring(10 - sec)
		dxDrawText(text, scale/2, scale/2, g_ScreenSize[1]+scale/2, g_ScreenSize[2]+scale/2, shadowClr, scale, 'bankgothic', 'center', 'center', false, false, true, false, true)
		dxDrawText(text, 0, 0, g_ScreenSize[1], g_ScreenSize[2], clr, scale, 'bankgothic', 'center', 'center', false, false, true, false, true)
	else
		removeEventHandler('onClientRender', root, renderCountDown)
		g_StartTicks = ticks
		setTimer(launchRocket, 1000, 20)
		addEventHandler('onClientRender', root, renderAnim)
	end
end

local function startAnim()
	g_StartTicks = getTickCount()
	addEventHandler('onClientRender', root, renderCountDown)
end

local function init()
	math.randomseed(getTickCount())
	local tm = getRealTime()
	if(tm.month == 11 and tm.monthday == 31) then
		local sec = (23 - tm.hour)*3600 + (59-tm.minute)*60 + (60-tm.second) - 10
		Debug.info('New year in '..sec..' seconds')
		setTimer(startAnim, sec*1000, 1)
	end
end

addEventHandler('onClientResourceStart', resourceRoot, init)
