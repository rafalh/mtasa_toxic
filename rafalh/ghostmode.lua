local g_NoGMWarningTimeLeft = 0
local g_NoGMWarningMsg = {}

local function GmSetEnabled ( enabled )
	local map = getCurrentMap()
	if (map:getSetting("ghostmode")) then
		return false
	end

	enabled = tostring ( enabled )
	local old_enabled = get ( "*race.ghostmode" )
	local race_res = getResourceFromName ( "race" )
	
	if ( race_res and getResourceState ( race_res ) == "running" ) then
		set ( "*race.ghostmode", enabled )
		triggerEvent ( "onSettingChange", getResourceRootElement ( race_res ), "ghostmode", old_enabled, enabled )
		return true
	end
	
	return false
end

local function GmOnPlayerQuit ()
	g_NoGMWarningMsg[source] = nil
end

function GmSet ( enabled, quiet )
	local sec = touint ( enabled )
	if ( sec ) then
		customMsg ( 0, 255, 0, "Ghostmode enabled for %u seconds!", sec )
		GmSetEnabled ( true )
		
		local no_gm_warning_time = SmGetUInt ( "no_gm_warning_time", 0 )
		local sec_before_warning = gm_time - no_gm_warning_time
		
		setMapTimer ( function ()
			g_NoGMWarningMsg = {}
			g_NoGMWarningTimeLeft = no_gm_warning_time
			for player, pdata in pairs ( g_Players ) do
				g_NoGMWarningMsg[player] = addScreenMsg ( "Ghostmode will be disabled in "..g_NoGMWarningTimeLeft.." seconds!", player, g_NoGMWarningTimeLeft * 1000 )
			end
			setMapTimer ( function ()
				g_NoGMWarningTimeLeft = g_NoGMWarningTimeLeft - 1
				if ( g_NoGMWarningTimeLeft <= 0 ) then
					if ( GmIsEnabled () ) then
						GmSetEnabled ( false )
						customMsg ( 255, 0, 0, "Ghostmode disabled!" )
					end
				else
					for player, msg in pairs ( g_NoGMWarningMsg ) do
						textItemSetText ( msg, "Ghostmode will be disabled in "..g_NoGMWarningTimeLeft.." seconds!" )
					end
				end
			end, 1000, g_NoGMWarningTimeLeft )
		end, sec_before_warning * 1000, 1 )
	else
		GmSetEnabled ( enabled )
		if ( not quiet ) then
			if ( enabled ) then
				customMsg ( 0, 255, 0, "Ghostmode enabled!" )
			else
				customMsg ( 255, 0, 0, "Ghostmode disabled!" )
			end
		end
	end
end

function GmIsEnabled ()
	local race_res = getResourceFromName ( "race" )
	
	if ( race_res and getResourceState ( race_res ) == "running" ) then
		return ( get ( "race.ghostmode" ) == "true" )
	end
	return false
end

addEventHandler ( "onPlayerQuit", g_Root, GmOnPlayerQuit )
