local g_Root = getRootElement()
local g_ResRoot = getResourceRootElement(getThisResource())
local g_SoundVolume = 0.5

addEvent("playClientAudio", true)
addEvent("onClientPlayerOutOfTime", true)

local function playAudio(filename)
	local sound = playSound("audio/"..filename)
	setSoundVolume(sound, g_SoundVolume)
end

local function onResStart()
	playAudio("raceon.mp3")
end

local function onClientPlayerOutOfTime()
	playAudio("timesup.mp3")
end

local function onSoundVolumeCmd(cmd, value)
	g_SoundVolume = value/100
	outputConsole("set sound volume to "..value.."%")
end

addEventHandler("playClientAudio", g_Root, playAudio)
addEventHandler("onClientResourceStart", g_ResRoot, onResStart)
addEventHandler("onClientPlayerOutOfTime", g_Root, onClientPlayerOutOfTime)
addCommandHandler("soundvolume", onSoundVolumeCmd, false, false)
