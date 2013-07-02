Settings.register
{
	name = "raceVolume",
	default = 100,
	cast = tonumber,
	onChange = function(oldVal, newVal)
		local res = getResourceFromName("race_audio")
		if(res) then
			call(res, "setRaceAudioVolume", newVal/200) -- normally its 0.5
		else
			outputChatBox("Failed to set Race Audio volume!", 255, 0, 0)
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		local label = guiCreateLabel(x, y, w, 15, "Race Audio Volume: "..Settings.raceVolume.."%", false, wnd)
		local bar = guiCreateScrollBar(x, y + 18, w - 50, 22, true, false, wnd)
		setElementData(bar, "tooltip", "Changes volume for Count Down, Checkpoints and Race Voice sounds")
		guiScrollBarSetScrollPosition(bar, Settings.raceVolume)
		if(onChange) then
			addEventHandler("onClientGUIScroll", bar, onChange, false)
		end
		return 40, {label, bar}
	end,
	acceptGui = function(info)
		local vol = guiScrollBarGetScrollPosition(info[2])
		guiSetText(info[1], "Race Audio Volume: "..vol.."%")
		Settings.raceVolume = vol
	end,
}
