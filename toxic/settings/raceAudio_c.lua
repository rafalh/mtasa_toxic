Settings.register
{
	name = "raceVolume",
	default = 100,
	cast = tonumber,
	onChange = function(oldVal, newVal)
		local res = getResourceFromName("race_audio")
		if(res) then
			--outputDebugString("Changing race audio volume to "..newVal/200, 3)
			call(res, "setRaceAudioVolume", newVal/200) -- normally its 0.5
		else
			outputChatBox("Failed to set Race Audio volume!", 255, 0, 0)
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		local text = MuiGetMsg("Race Audio Volume: %u%%"):format(Settings.raceVolume)
		local label = guiCreateLabel(x, y, w, 15, text, false, wnd)
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
		local text = MuiGetMsg("Race Audio Volume: %u%%"):format(vol)
		guiSetText(info[1], text)
		Settings.raceVolume = vol
	end,
}
