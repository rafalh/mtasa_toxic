local g_RaceAudioRes = Resource('race_audio')
local g_MapMusicRes = Resource('mapmusic')

Settings.register
{
	name = 'raceVolume',
	default = 100,
	cast = tonumber,
	priority = 60,
	onChange = function(oldVal, newVal)
		if(not g_RaceAudioRes:isReady()) then return end
		--outputDebugString('Changing race audio volume to '..newVal/200, 3)
		g_RaceAudioRes:call('setRaceAudioVolume', newVal/200) -- normally its 0.5
	end,
	createGui = function(wnd, x, y, w, onChange)
		local label = FormattedLabel(x, y + 5, 190, 15, wnd, "Race Audio Volume: %u%%", Settings.raceVolume)
		local bar = guiCreateScrollBar(x + 190, y + 2, w - 210, 22, true, false, wnd)
		setElementData(bar, 'tooltip', "Changes volume for Count Down, Checkpoints and Race Voice sounds")
		guiScrollBarSetScrollPosition(bar, Settings.raceVolume)
		if(onChange) then
			addEventHandler('onClientGUIScroll', bar, onChange, false)
		end
		return 22, {label, bar}
	end,
	acceptGui = function(info)
		local vol = guiScrollBarGetScrollPosition(info[2])
		info[1]:setText("Race Audio Volume: %u%%", vol)
		Settings.raceVolume = vol
	end,
}

Settings.register
{
	name = 'cmdVolume',
	default = 100,
	cast = tonumber,
	priority = 60,
	onChange = function(oldVal, newVal)
		McSetVolume(newVal)
	end,
	createGui = function(wnd, x, y, w, onChange)
		local label = FormattedLabel(x, y + 5, 190, 15, wnd, "Commands Volume: %u%%", Settings.cmdVolume)
		local bar = guiCreateScrollBar(x + 190, y + 2, w - 210, 22, true, false, wnd)
		setElementData(bar, 'tooltip', "Changes volume for commands with sound")
		guiScrollBarSetScrollPosition(bar, Settings.cmdVolume)
		if(onChange) then
			addEventHandler('onClientGUIScroll', bar, onChange, false)
		end
		return 22, {label, bar}
	end,
	acceptGui = function(info)
		local vol = guiScrollBarGetScrollPosition(info[2])
		info[1]:setText("Commands Volume: %u%%", vol)
		Settings.cmdVolume = vol
	end,
}

Settings.register
{
	name = 'musicVolume',
	default = 100,
	cast = tonumber,
	priority = 60,
	onChange = function(oldVal, newVal)
		if(not g_MapMusicRes:isReady()) then return end
		g_MapMusicRes:call('setMusicVolume', newVal)
	end,
	createGui = function(wnd, x, y, w, onChange)
		local label = FormattedLabel(x, y + 5, 190, 15, wnd, "Map Music Volume: %u%%", Settings.musicVolume)
		local bar = guiCreateScrollBar(x + 190, y + 2, w - 210, 22, true, false, wnd)
		setElementData(bar, 'tooltip', "Changes volume for map music")
		guiScrollBarSetScrollPosition(bar, Settings.musicVolume)
		if(onChange) then
			addEventHandler('onClientGUIScroll', bar, onChange, false)
		end
		return 22, {label, bar}
	end,
	acceptGui = function(info)
		local vol = guiScrollBarGetScrollPosition(info[2])
		info[1]:setText("Map Music Volume: %u%%", vol)
		Settings.musicVolume = vol
	end,
}

g_RaceAudioRes:addReadyHandler(function()
	--outputDebugString('race_audio start detected', 3)
	g_RaceAudioRes:call('setRaceAudioVolume', Settings.raceVolume/200) -- normally its 0.5
end)

g_MapMusicRes:addReadyHandler(function()
	g_RaceAudioRes:call('setMusicVolume', Settings.musicVolume) -- normally its 0.5
end)
