--------------
-- Includes --
--------------

#include "../include/serv_verification.lua"

-----------------
-- Definitions --
-----------------

#AUTUMN_COLORS = false
#IMAGES = { "snow.png" }

#FLAKE_X = 1
#FLAKE_Y = 2
#FLAKE_Z = 3
#FLAKE_ANGLE = 4
#FLAKE_SIZE = 5
#FLAKE_ROT_SPEED = 6
#FLAKE_FADEOUT_START = 7
#if ( #IMAGES > 1 ) then
#FLAKE_IMAGE = 8
#end
#if ( AUTUMN_COLORS ) then
#FLAKE_COLOR1 = ( #IMAGES > 1 and 9 ) or 8
#FLAKE_COLOR2 = ( #IMAGES > 1 and 10 ) or 9
#end

----------------------
-- Global variables --
----------------------

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenHeightSqrt = g_ScreenSize[2]^0.5
local g_Particles = {}
local g_LastSnowUpdate = getTickCount ()
local g_Radius = 20
local g_Density = 50
local g_Speed = 1.5
local g_Size = 1
local g_WindX = 0
local g_WindY = 0
local g_Rotate = 5
#if ( #IMAGES > 1 ) then
local g_Images = { "$(table.concat ( IMAGES, "\", \"" ))" }
#end
local g_Tex = dxCreateTexture("$(IMAGES[1])")
-------------------
-- Custom events --
-------------------

addEvent ( "onClientRafalhConfigureParticles", true )
addEvent ( "onRafalhParticlesInit", true )

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

-- used in effect_c.lua
function renderParticles ()
	local t = getTickCount ()
	local delta = (t - g_LastSnowUpdate)/1000
	local cx, cy, cz, lx, ly, lz = getCameraMatrix ()
	local x, y, z = ptOnLine (cx, cy, cz, lx, ly, lz, g_Radius - 1)
	
	-- Calculate physics
	
	for i, particle in ipairs(g_Particles) do
		local dist = getDistanceBetweenPoints3D ( particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)], x, y, z )
		if(dist > g_Radius or (particle[$(FLAKE_FADEOUT_START)] and t - particle[$(FLAKE_FADEOUT_START)] > 1000)) then
			local anglez = math.random ( 0, 359 )
			local anglex = math.random ( 30, 75 )
			local r = g_Radius * math.sin ( anglex )
#if ( AUTUMN_COLORS ) then
			local br = math.random () * 2
#end
			
			particle = {
				x + math.cos ( anglez ) * r, -- x
				y + math.sin ( anglez ) * r, -- y
				z + math.tan ( anglex ) * r, -- z
				math.random ( 0, 359 ), -- anglez
				math.random ( 80, 120 ) / 100, -- size
				( math.random () - 0.5 ) * g_Rotate, -- rotation speed
				false -- fade out start time
#if ( #IMAGES > 1 ) then
				, g_Images[math.random ( 1, #g_Images )]
#end
#if ( AUTUMN_COLORS ) then
				, ( br <= 1 and math.random ( 128, 255 ) ) or math.random ( 128, 255 ) * ( br - 1 ), -- color1
				( br <= 1 and math.random ( 128, 255 ) * br ) or math.random ( 128, 255 ) -- color2
#end
			}
		elseif ( not particle[$(FLAKE_FADEOUT_START)] ) then
			--local gz = getGroundPosition ( particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)] )
			--if ( ( particle[$(FLAKE_Z)] - delta * g_Speed ) < gz ) then
			if ( not isLineOfSightClear ( particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)], particle[$(FLAKE_X)] + delta * g_WindX, particle[$(FLAKE_Y)] + delta * g_WindY, particle[$(FLAKE_Z)] - delta * g_Speed ) ) then
				particle[$(FLAKE_FADEOUT_START)] = t
			else
				particle = {
					particle[$(FLAKE_X)] + delta * g_WindX,
					particle[$(FLAKE_Y)] + delta * g_WindY,
					particle[$(FLAKE_Z)] - delta * g_Speed,
					particle[$(FLAKE_ANGLE)] + particle[$(FLAKE_ROT_SPEED)],
					particle[$(FLAKE_SIZE)],
					particle[$(FLAKE_ROT_SPEED)],
					false
#if ( #IMAGES > 1 ) then
					, particle[$(FLAKE_IMAGE)]
#end
#if ( AUTUMN_COLORS ) then
					, particle[$(FLAKE_COLOR1)],
					particle[$(FLAKE_COLOR2)]
#end
				}
			end
		end
		
		g_Particles[i] = particle
		
		-- Render the flake
		
		if ( isLineOfSightClear ( cx, cy, cz, particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)] ) ) then
			local screenX, screenY = getScreenFromWorldPosition ( particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)] )
			
			if ( screenX ) then
				--local size = g_Size*256*g_ScreenHeightSqrt/33/getDistanceBetweenPoints3D ( cx, cy, cz, particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)] ) * particle[$(FLAKE_SIZE)]
				local size = g_Size*8*g_ScreenHeightSqrt/getDistanceBetweenPoints3D ( cx, cy, cz, particle[$(FLAKE_X)], particle[$(FLAKE_Y)], particle[$(FLAKE_Z)] ) * particle[$(FLAKE_SIZE)]
#if ( AUTUMN_COLORS ) then
				dxDrawImage ( screenX - size/2, screenY - size/2, size, size, $(( #IMAGES > 1 and "particle["..FLAKE_IMAGE.."]" ) or "\""..IMAGES[1].."\""), particle[4], 0, 0, tocolor ( particle[$(FLAKE_COLOR1)], particle[$(FLAKE_COLOR2)], 0, ( particle[$(FLAKE_FADEOUT_START)] and ( 1 - ( t - particle[$(FLAKE_FADEOUT_START)] )/1000 )*255 ) or 255 ) )
#else
				local h, m = getTime ()
				--local clr = 255 - math.abs ( ( h + m/60 )/12 - 1 ) * 64
				local clr = 255 - math.abs ( 12 - h - m/60 )/$(12*63) -- 0:00 - 196, 12:00 - 255
				dxDrawImage ( screenX - size / 2, screenY - size / 2, size, size, g_Tex, particle[$(FLAKE_ANGLE)], 0, 0, tocolor ( clr, clr, clr, ( particle[$(FLAKE_FADEOUT_START)] and ( 1 - ( t - particle[$(FLAKE_FADEOUT_START)] )/1000 )*255 ) or 255 ) )
#end
			end
		end
	end
	
	g_LastSnowUpdate = t
end

local function onInit ()
	triggerServerEvent ( "onRafalhParticlesInit", g_Root )
end

local function onConfig ( radius, density, speed, size, wind_x, wind_y )
	g_Radius = ( radius and tonumber ( radius ) ) or 20
	g_Density = ( density and tonumber ( density ) ) or 50
	g_Speed = ( speed and tonumber ( speed ) ) or 1.5
	g_Size = ( speed and tonumber ( size ) ) or 1
	g_WindX = ( wind_x and tonumber ( wind_x ) ) or 0
	g_WindY = ( wind_y and tonumber ( wind_y ) ) or 0
	
	g_Particles = {}
	for i = 1, g_Density, 1 do
		g_Particles[i] = { 0, 0, 0, 0, 0, 0, false
#if ( #IMAGES > 1 ) then
		, g_Images[math.random ( 1, #g_Images )]
#end
#if ( AUTUMN_COLORS ) then
		, 0, 0
#end
		}
	end
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN ( "6B3737E598A38774517058B15CF09700" )
	addEventHandler ( "onClientResourceStart", getResourceRootElement(), onInit )
	addEventHandler ( "onClientRafalhConfigureParticles", g_Root, onConfig )
#VERIFY_SERVER_END ()
