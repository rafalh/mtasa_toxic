local g_Volume = 100
local g_Sound

local function McSoundStopped()
	destroyElement(source)
	g_Sound = false
end

local function McSoundStream(success)
	if(not success) then
		outputDebugString('Failed to stream sound command', 2)
		McSoundStopped()
	end
end

function McSetVolume(vol)
	g_Volume = vol or 100
end

function McPlaySound(path, sender)
	if(g_Sound) then
		if(sender == localPlayer) then
			outputMsg(Styles.red, "Wait until another sound command finishes playing!")
		end
		return
	end
	
	g_Sound = playSound(path)
	if(g_Sound) then
		setSoundVolume(g_Sound, g_Volume/100)
		addEventHandler('onClientSoundStopped', g_Sound, McSoundStopped)
		addEventHandler('onClientSoundStream', g_Sound, McSoundStream)
	end
end
