local g_Volume = 100

function McSetVolume(vol)
	g_Volume = vol or 100
end

function McPlaySound(path)
	local sound = playSound(path)
	if(sound) then
		setSoundVolume(sound, g_Volume/100)
	end
end
