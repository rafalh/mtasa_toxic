local g_NoGMWarningTimeLeft = 0
local g_NoGMWarningMsg = {}

local function GmSetEnabled(room, enabled)
	local map = getCurrentMap(room)
	if(not map) then return false end
	
	assert(type(map) == "table", type(map))
	
	if (map:getSetting("ghostmode")) then
		return false
	end
	
	enabled = tostring(enabled)
	local oldEnabled = get("*race.ghostmode")
	local raceRes = getResourceFromName("race")
	
	if(raceRes and getResourceState(raceRes) == "running") then
		set("*race.ghostmode", enabled)
		local raceResRoot = getResourceRootElement(raceRes)
		triggerEvent("onSettingChange", raceResRoot, "ghostmode", oldEnabled, enabled)
		return true
	end
	
	return false
end

local function GmOnPlayerQuit()
	g_NoGMWarningMsg[source] = nil
end

function GmSet(room, enabled, quiet)
	assert(type(room) == "table")
	
	local sec = touint(enabled)
	if (sec) then
		customMsg(0, 255, 0, "Ghostmode enabled for %u seconds!", sec)
		GmSetEnabled(room, true)
		
		local no_gm_warning_time = SmGetUInt("no_gm_warning_time", 0)
		local sec_before_warning = gm_time - no_gm_warning_time
		
		setMapTimer(function(room)
			g_NoGMWarningMsg = {}
			g_NoGMWarningTimeLeft = no_gm_warning_time
			for player, pdata in pairs(g_Players) do
				g_NoGMWarningMsg[player] = addScreenMsg("Ghostmode will be disabled in "..g_NoGMWarningTimeLeft.." seconds!", player, g_NoGMWarningTimeLeft * 1000)
			end
			setMapTimer(function(room)
				g_NoGMWarningTimeLeft = g_NoGMWarningTimeLeft - 1
				if(g_NoGMWarningTimeLeft <= 0) then
					if(GmIsEnabled(room)) then
						customMsg(255, 0, 0, "Ghostmode disabled!")
					end
					GmSetEnabled(room, false)
				else
					for player, msg in pairs(g_NoGMWarningMsg) do
						textItemSetText(msg, "Ghostmode will be disabled in "..g_NoGMWarningTimeLeft.." seconds!")
					end
				end
			end, 1000, g_NoGMWarningTimeLeft, room)
		end, sec_before_warning * 1000, 1, room)
	else
		if(not quiet and GmIsEnabled(room) ~= enabled) then
			if(enabled) then
				customMsg(0, 255, 0, "Ghostmode enabled!")
			else
				customMsg(255, 0, 0, "Ghostmode disabled!")
			end
		end
		GmSetEnabled(room, enabled)
	end
end

function GmIsEnabled(room)
	local raceRes = getResourceFromName("race")
	if(not raceRes or getResourceState(raceRes) ~= "running") then
		return false
	end
	
	local map = getCurrentMap(room)
	if(not map) then return false end
	
	local ghostModeStr = map:getSetting("ghostmode") or get("*race.ghostmode")
	return (ghostModeStr == "true")
end

addEventHandler("onPlayerQuit", g_Root, GmOnPlayerQuit)

CmdRegister("testgm", function()
	local pdata = g_Players[source]
	outputChatBox("TEST GM: "..tostring(GmIsEnabled(pdata.room)))
end, true)
