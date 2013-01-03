--------------
-- Includes --
--------------

#include "../include/serv_verification.lua"

-----------------
-- Definitions --
-----------------

#AUTUMN_COLORS = false

#FLAKE_X = 1
#FLAKE_Y = 2
#FLAKE_Z = 3
#FLAKE_ANGLE = 4
#FLAKE_SIZE = 5
#FLAKE_ROT_SPEED = 6
#FLAKE_FADEOUT_START = 7
#FLAKE_IMAGE = 8
#if ( AUTUMN_COLORS ) then
#FLAKE_COLOR1 = 9
#FLAKE_COLOR2 = 10
#end

----------------------
-- Global variables --
----------------------

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenHeightSqrt = g_ScreenSize[2]^0.5
local g_Particles = {}
local g_LastSnowUpdate = getTickCount()
local g_Radius = 20
local g_Density = 50
local g_Speed = 1.5
local g_Size = 1
local g_WindX = 0
local g_WindY = 0
local g_Rotate = 5
local IMAGE_PATHES = {"snow.png"}
local g_Images = {}

-------------------
-- Custom events --
-------------------

addEvent ( "particles_onConfig", true )
addEvent ( "particles_onPlayerReady", true )

--------------------------------
-- Local function definitions --
--------------------------------

local function ptOnLine(x, y, z, x2, y2, z2, dist)
	local t = dist/getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
	return
		x + ( x2 - x )*t,
		y + ( y2 - y )*t,
		z + ( z2 - z )*t
end

local function resetParticle(particle, x, y, z)
	local anglez = math.random(0, 359)
	local anglex = math.random(30, 75)
	local r = g_Radius * math.sin(anglex)
#if(AUTUMN_COLORS) then
	local br = math.random() * 2
#end

	particle[$(FLAKE_X)] = x + math.cos(anglez) * r -- x
	particle[$(FLAKE_Y)] = y + math.sin(anglez) * r -- y
	particle[$(FLAKE_Z)] = z + math.tan(anglex) * r -- z
	particle[$(FLAKE_ANGLE)] = math.random(0, 359) -- anglez
	particle[$(FLAKE_SIZE)] = math.random(80, 120) / 100 -- size
	particle[$(FLAKE_ROT_SPEED)] = (math.random () - 0.5) * g_Rotate -- rotation speed
	particle[$(FLAKE_FADEOUT_START)] = false -- fade out start time
	particle[$(FLAKE_IMAGE)] = g_Images[math.random(1, #g_Images)]
#if(AUTUMN_COLORS) then
	particle[$(FLAKE_COLOR1)] = (br <= 1 and math.random(128, 255)) or math.random(128, 255) * (br - 1) -- color1
	particle[$(FLAKE_COLOR2)] = (br <= 1 and math.random(128, 255) * br) or math.random(128, 255) -- color2
#end
end

-- used in effect_c.lua
local function renderParticles ()
	local ticks = getTickCount()
	local delta = (ticks - g_LastSnowUpdate)/1000
	local cx, cy, cz, lx, ly, lz = getCameraMatrix()
	local x, y, z = ptOnLine(cx, cy, cz, lx, ly, lz, g_Radius - 1)
	
#if(not AUTUMN_COLORS) then
	local h, m = getTime()
	local brightness = 255 - math.abs(12 - h - m/60)/$(12*63) -- 0:00 - 196, 12:00 - 255
#end
	
	local dx = delta * g_WindX
	local dy = delta * g_WindY
	local dz = -delta * g_Speed
	
	-- Process all particles
	for i, particle in ipairs(g_Particles) do
		-- Calculate physics
		local fx, fy, fz = particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)]
		local dist = getDistanceBetweenPoints3D(fx, fy, fz, x, y, z)
		local fadeout_delta = particle[$(FLAKE_FADEOUT_START)] and (ticks - particle[$(FLAKE_FADEOUT_START)])
		
		if(dist > g_Radius or (fadeout_delta and fadeout_delta > 1000)) then
			-- Destroy particle and create new
			resetParticle(particle, x, y, z)
			fx, fy, fz = particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)] -- get new position
		elseif(not fadeout_delta) then
			-- Move particle
			local newX = fx + dx
			local newY = fy + dy
			local newZ = fz + dz
			if(not isLineOfSightClear(fx, fy, fz, newX, newY, newZ)) then
				-- Hide it
				particle[$(FLAKE_FADEOUT_START)] = ticks
			else
				-- Change position and angle
				particle[$(FLAKE_X)] = newX
				particle[$(FLAKE_Y)] = newY
				particle[$(FLAKE_Z)] = newZ
				particle[$(FLAKE_ANGLE)] = particle[$(FLAKE_ANGLE)] + particle[$(FLAKE_ROT_SPEED)]
			end
		end
		
		-- Render flake
		if(isLineOfSightClear(cx, cy, cz, fx, fy, fz)) then
			local screenX, screenY = getScreenFromWorldPosition(fx, fy, fz)
			
			if(screenX) then
				local camDist = getDistanceBetweenPoints3D(cx, cy, cz, fx, fy, fz)
				local size = g_Size*8*g_ScreenHeightSqrt/camDist*particle[$(FLAKE_SIZE)]
				local a = 255
				if(fadeout_delta) then
					a = (1 - fadeout_delta/1000)*255
				end
#if(AUTUMN_COLORS) then
				local clr = tocolor(particle[$(FLAKE_COLOR1)], particle[$(FLAKE_COLOR2)], 0, a)
#else
				local clr = tocolor(brightness, brightness, brightness, a)
#end
				dxDrawImage(screenX - size/2, screenY - size/2, size, size, particle[$(FLAKE_IMAGE)], particle[$(FLAKE_ANGLE)], 0, 0, clr)
			end
		end
	end
	
	g_LastSnowUpdate = ticks
end

function enableParticles()
	addEventHandler("onClientRender", g_Root, renderParticles)
	
	for i, path in ipairs(IMAGE_PATHES) do
		g_Images[i] = dxCreateTexture(path)
	end
	
	for i, particle in ipairs(g_Particles) do
		resetParticle(particle, 0, 0, 0)
	end
end

function disableParticles()
	removeEventHandler("onClientRender", g_Root, renderParticles)
	
	for i, tex in ipairs(g_Images) do
		destroyElement(tex)
	end
	g_Images = {}
end

local function onConfig(radius, density, speed, size, wind_x, wind_y)
	g_Radius = (radius and tonumber(radius)) or 20
	g_Density = (density and tonumber(density)) or 50
	g_Speed = (speed and tonumber(speed)) or 1.5
	g_Size = (speed and tonumber(size)) or 1
	g_WindX = (wind_x and tonumber(wind_x)) or 0
	g_WindY = (wind_y and tonumber(wind_y)) or 0
	
	g_Particles = {}
	for i = 1, g_Density do
		g_Particles[i] = { 0, 0, 0, 0, 0, 0, false,
		g_Images[math.random(1, #g_Images)]
#if(AUTUMN_COLORS) then
		, 0, 0
#end
		}
	end
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN("6B3737E598A38774517058B15CF09700")
	addEventHandler("particles_onConfig", resourceRoot, onConfig)
	
	triggerServerEvent("particles_onPlayerReady", resourceRoot)
#VERIFY_SERVER_END()
