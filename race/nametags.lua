﻿nametag = {}
local nametags = {}
local g_screenX,g_screenY = guiGetScreenSize()
local bHideNametags = true --false
		--local g_Me = false
local NAMETAG_SCALE = 0.3 --Overall adjustment of the nametag, use this to resize but constrain proportions
local NAMETAG_ALPHA_DISTANCE = 50 --Distance to start fading out
local NAMETAG_DISTANCE = 120 --Distance until we're gone
local NAMETAG_ALPHA = 120 --The overall alpha level of the nametag
--The following arent actual pixel measurements, they're just proportional constraints
local NAMETAG_TEXT_BAR_SPACE = 2
local NAMETAG_WIDTH = 50
local NAMETAG_HEIGHT = 5
local NAMETAG_TEXTSIZE = 0.7
local NAMETAG_OUTLINE_THICKNESS = 0.5
--
local NAMETAG_ALPHA_DIFF = NAMETAG_DISTANCE - NAMETAG_ALPHA_DISTANCE
NAMETAG_SCALE = 1/NAMETAG_SCALE * 800 / g_screenY 

-- Ensure the name tag doesn't get too big
local maxScaleCurve = { {0, 0}, {3, 3}, {13, 5} }
-- Ensure the text doesn't get too small/unreadable
local textScaleCurve = { {0, 0.8}, {0.8, 1.2}, {99, 99} }
-- Make the text a bit brighter and fade more gradually
local textAlphaCurve = { {0, 0}, {25, 100}, {120, 190}, {255, 190} }

function nametag.create ( player )
	nametags[player] = {}
	local clr = getElementData ( player, "nametag_color" )
	if ( clr ) then
		local r, g, b = clr:match ( "^#(%x%x)(%x%x)(%x%x)$" )
		if ( r ) then
			nametags[player][1] = { tonumber ( "0x"..r ), tonumber ( "0x"..g ), tonumber ( "0x"..b ) }
		end
	end
	nametags[player][2] = ( getElementData ( player, "nametag_hidden" ) == "1" ) or nil
end

function nametag.destroy ( player )
	nametags[player] = nil
end

addEventHandler ( "onClientRender", g_Root,
	function()
		-- Hideous quick fix --
		for i,player in ipairs(g_Players) do
			--if player ~= g_Me then
				setPlayerNametagShowing ( player, false )
				if not nametags[player] then
					nametag.create ( player )
				end
			--end
		end
		if bHideNametags then
			return
		end
		local x,y,z = getCameraMatrix()
		for player, data in pairs(nametags) do 
			while true do
				if not isPedInVehicle(player) or isPlayerDead(player) or data[2] then break end
				local vehicle = getPedOccupiedVehicle(player)
				local px,py,pz = getElementPosition ( vehicle )
				local pdistance = getDistanceBetweenPoints3D ( x,y,z,px,py,pz )
				if pdistance <= NAMETAG_DISTANCE then
					--Get screenposition
					local sx,sy = getScreenFromWorldPosition ( px, py, pz+0.95, 0.06 )
					if not sx or not sy then break end
					--Calculate our components
					local scale = 1/(NAMETAG_SCALE * (pdistance / NAMETAG_DISTANCE))
					local alpha = ((pdistance - NAMETAG_ALPHA_DISTANCE) / NAMETAG_ALPHA_DIFF)
					alpha = (alpha < 0) and NAMETAG_ALPHA or NAMETAG_ALPHA-(alpha*NAMETAG_ALPHA)
					scale = math.evalCurve(maxScaleCurve,scale)
					local textscale = math.evalCurve(textScaleCurve,scale)
					local textalpha = math.evalCurve(textAlphaCurve,alpha)
					local outlineThickness = math.floor ( NAMETAG_OUTLINE_THICKNESS*(scale)+0.5 )
					--Draw our text
					local r,g,b = 255,255,255
					local team = getPlayerTeam(player)
					if data[1] then
						r, g, b = data[1][1], data[1][2], data[1][3]
					elseif team then
						r,g,b = getTeamColor(team)
					end
					local offset = math.floor ( (scale) * NAMETAG_TEXT_BAR_SPACE/2 + 0.5 )
					local tx, ty = math.floor ( sx + 0.5 ), math.floor ( sy - offset + 0.5 )
					dxDrawText ( getPlayerName(player), tx, ty, tx, ty, tocolor(r,g,b,textalpha), textscale*NAMETAG_TEXTSIZE, "default", "center", "bottom", false, false, false )
					--We draw three parts to make the healthbar.  First the outline/background
					local drawX = math.floor ( sx - NAMETAG_WIDTH*scale/2 + 0.5 )
					local drawY = math.floor ( sy + offset + 0.5 )
					local width,height = math.floor ( NAMETAG_WIDTH*scale + 0.5 ), math.floor ( NAMETAG_HEIGHT*scale + 0.5 )
					dxDrawRectangle ( drawX, drawY, width, height, tocolor(0,0,0,alpha) )
					--Next the inner background 
					local health = getElementHealth(vehicle)
					health = math.max(health - 250, 0)/750
					local p = -510*(health^2)
					local r,g = math.max(math.min(p + 255*health + 255, 255), 0), math.max(math.min(p + 765*health, 255), 0)
					dxDrawImage ( 	drawX + outlineThickness,
									drawY + outlineThickness,
									width - outlineThickness*2,
									height - outlineThickness*2,
									"img/nametag_health.png", 0, 0, 0, tocolor(r,g,0,0.4*alpha )
								)
					--Finally, the actual health
					dxDrawImage ( 	drawX + outlineThickness,
									drawY + outlineThickness,
									health*(width - outlineThickness*2),
									height - outlineThickness*2,
									"img/nametag_health.png", 0, 0, 0, tocolor(r,g,0,alpha)
								)
				end
				break
			end
		end
	end
)


---------------THE FOLLOWING IS THE MANAGEMENT OF NAMETAGS-----------------
addEventHandler('onClientResourceStart', g_ResRoot,
	function()
		for i,player in ipairs(getElementsByType"player") do
			if player ~= g_Me then
				nametag.create ( player )
			end
		end
	end
)

addEventHandler ( "onClientPlayerJoin", g_Root,
	function()
		if source == g_Me then return end
		setPlayerNametagShowing ( source, false )
		nametag.create ( source )
	end
)

addEventHandler ( "onClientPlayerQuit", g_Root,
	function()
		nametag.destroy ( source )
	end
)


addEvent ( "onClientScreenFadedOut", true )
addEventHandler ( "onClientScreenFadedOut", g_Root,
	function()
		bHideNametags = true
	end
)

addEvent ( "onClientScreenFadedIn", true )
addEventHandler ( "onClientScreenFadedIn", g_Root,
	function()
		--bHideNametags = false
	end
)

addEventHandler ( "onClientElementDataChange", g_Root, function ( name )
	if ( ( name == "nametag_color" or name == "nametag_hidden" ) and nametags[source] ~= nil ) then
		nametag.create ( source )
	end
end )
