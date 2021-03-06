local g_NoGMWarningTimeLeft = 0
local g_NoGMWarningMsg = {}
local g_RaceRes = Resource('race')

local function GmSetEnabled(room, enabled)
	local map = getCurrentMap(room)
	if(not map) then return false end
	
	assert(type(map) == 'table', type(map))
	
	--[[if (map:getSetting('ghostmode')) then
		return false
	end
	
	enabled = tostring(enabled)
	local oldEnabled = get('*race.ghostmode')
	
	if(g_RaceRes:isReady()) then
		set('*race.ghostmode', enabled)
		local raceResRoot = getResourceRootElement(raceRes)
		triggerEvent('onSettingChange', raceResRoot, 'ghostmode', oldEnabled, enabled)
		return true
	end
	
	return false]]
	
	if(not g_RaceRes:isReady()) then
		return false
	end
	
	g_RaceRes:call('setGhostmodeEnabled', enabled)
	return true
end

local function GmOnPlayerQuit()
	g_NoGMWarningMsg[source] = nil
end

function GmSet(room, enabled, quiet)
	assert(type(room) == 'table')
	
	local sec = touint(enabled)
	if (sec) then
		outputMsg(room, Styles.green, "Ghost Mode is enabled for %u seconds!", sec)
		GmSetEnabled(room, true)
		
		local no_gm_warning_time = Settings.no_gm_warning_time
		local sec_before_warning = gm_time - no_gm_warning_time
		
		setMapTimer(function(room)
			g_NoGMWarningMsg = {}
			g_NoGMWarningTimeLeft = no_gm_warning_time
			for player, pdata in pairs(g_Players) do
				g_NoGMWarningMsg[player] = addScreenMsg('Ghost Mode will be disabled in '..g_NoGMWarningTimeLeft..' seconds!', player, g_NoGMWarningTimeLeft * 1000)
			end
			setMapTimer(function(room)
				g_NoGMWarningTimeLeft = g_NoGMWarningTimeLeft - 1
				if(g_NoGMWarningTimeLeft <= 0) then
					if(GmIsEnabled(room)) then
						outputMsg(room, Styles.red, "Ghost Mode has been disabled!")
					end
					GmSetEnabled(room, false)
				else
					for player, msg in pairs(g_NoGMWarningMsg) do
						textItemSetText(msg, 'Ghost Mode will be disabled in '..g_NoGMWarningTimeLeft..' seconds!')
					end
				end
			end, 1000, g_NoGMWarningTimeLeft, room)
		end, sec_before_warning * 1000, 1, room)
	else
		if(not quiet and GmIsEnabled(room) ~= enabled) then
			if(enabled) then
				outputMsg(room, Styles.green, "Ghost Mode has been enabled!")
			else
				outputMsg(room, Styles.red, "Ghost Mode has been disabled!")
			end
		end
		GmSetEnabled(room, enabled)
	end
end

function GmIsEnabled(room)
	if(not g_RaceRes:isReady()) then
		return false
	end
	
	return g_RaceRes:call('isGhostmodeEnabled')
	
	--[[local map = getCurrentMap(room)
	if(not map) then return false end
	
	local ghostModeStr = map:getSetting('ghostmode') or get('*race.ghostmode')
	return (ghostModeStr == 'true')]]
end

addInitFunc(function()
	addEventHandler('onPlayerQuit', g_Root, GmOnPlayerQuit)
end)
