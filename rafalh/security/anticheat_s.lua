local g_HighSpeedAllowed = false

---------------------------------
-- Global function definitions --
---------------------------------

table.insert ( g_CustomRights, "ac_messages" )

function AcAllowHighSpeed ( allow )
	g_HighSpeedAllowed = allow
end

local function AcCheckPlayer ( player )
	-- max vielocity
	local max_v = SmGetNum ( "max_viel", 0 )
	if ( max_v > 0 and not isPedDead ( player ) and not g_HighSpeedAllowed ) then
		local speedx, speedy = getElementVelocity ( player )
		local speed = ( ( speedx^2 + speedy^2 )^0.5 ) * 161
		
		if ( speed > max_v ) then
			if ( not SmGetBool ( "max_viel_kick" ) ) then
				local show_msg = true
				for player2, pdata2 in pairs ( g_Players ) do
					if ( hasObjectPermissionTo ( player2, "resource.rafalh.ac_messages", false ) ) then
						privMsg ( player2, "%s's speed in horizontal plane: %.1f km/h. He seems to cheat!", getPlayerName ( player ), speed )
						show_msg = false
					end
				end
				
				if ( show_msg and SmGetBool ( "show_ac_msgs" ) ) then
					scriptMsg ( "%s's speed in horizontal plane: %.1f km/h. He seems to cheat!", getPlayerName ( player ), speed )
				end
			else
				scriptMsg ( "Kicking %s because of his speed in horizontal plane: %.1f km/h. He seems to cheat!", getPlayerName ( player ), speed )
				return kickPlayer ( player, "Your speed is too high - cheat" )
			end
		end
	end
	
	-- fps anticheat
	if ( SmGetBool ( "fps_anticheat" ) ) then
		local pdata = g_Players[player]
		local fps = tonumber ( getElementData ( player, "fps" ) )
		local fps_limit = getFPSLimit ()
		if ( fps and fps_limit > 0 and fps > fps_limit + 5 ) then
			if ( not pdata.fps_cheat ) then
				pdata.fps_cheat = getTickCount ()
			elseif ( ( getTickCount () - pdata.fps_cheat ) > 15000 ) then
				scriptMsg ( "Kicking %s for too high FPS. He is propably a cheater. His FPS: %u. FPS limit: %u.", getPlayerName ( player ), fps, fps_limit )
				return kickPlayer ( player, "FPS above the limit - cheat" )
			end
		else
			pdata.fps_cheat = nil
		end
	end
	
	return false
end

local function AcCheckAllPlayers ()
	for player, pdata in pairs ( g_Players ) do
		if ( not pdata.is_console ) then
			AcCheckPlayer ( player )
		end
	end
end

local function AcInit ()
	setTimer ( AcCheckAllPlayers, 1000, 0 )
end

addEventHandler ( "onResourceStart", g_ResRoot, AcInit )
