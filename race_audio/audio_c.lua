local g_SoundVolume = 0.5
local g_UnmuteRadioTimer = false

addEvent("playClientAudio", true)
addEvent("onClientPlayerOutOfTime", true)
addEvent("onClientPlayerHitPickup", true)
addEvent("onClientPlayerReachCheckpoint", true)
addEvent("onClientRaceCountdown", true)

local function playAudio(filename)
	local sound = playSound("audio/"..filename)
	setSoundVolume(sound, g_SoundVolume)
end

local function onRadioSwitch()
	cancelEvent()
end

local function unmuteRadio(prevChannel)
	removeEventHandler("onClientPlayerRadioSwitch", root, onRadioSwitch)
	setRadioChannel(prevChannel)
	g_UnmuteRadioTimer = false
end

local function muteRadio(ms)
	if(g_UnmuteRadioTimer) then
		resetTimer(g_UnmuteRadioTimer)
	else
		local ch = getRadioChannel()
		setRadioChannel(0)
		addEventHandler("onClientPlayerRadioSwitch", root, onRadioSwitch)
		setTimer(unmuteRadio, ms, 1, ch)
	end
end

local function onResStart()
	playAudio("raceon.mp3")
end

local function onOutOfTime()
	playAudio("timesup.mp3")
end

local function onHitPickup()
	playSoundFrontEnd(46)
end

local function onReachCheckpoint()
	playAudio("cp.mp3")
end

local function onFinish()
	playAudio("mission_accomplished.mp3")
	muteRadio(8000)
end

local function onCountdown(num)
	if(num > 0) then
		playAudio("countdown.mp3")
	else
		playAudio("go.mp3")
	end
end

local function onSoundVolumeCmd(cmd, value)
	g_SoundVolume = value/100
	outputConsole("set sound volume to "..value.."%")
end

addEventHandler("playClientAudio", root, playAudio)
addEventHandler("onClientResourceStart", resourceRoot, onResStart)
addEventHandler("onClientPlayerOutOfTime", root, onOutOfTime)
addEventHandler("onClientPlayerHitPickup", localPlayer, onHitPickup)
addEventHandler("onClientPlayerReachCheckpoint", localPlayer, onReachCheckpoint)
addEventHandler("onClientPlayerFinish", localPlayer, onFinish)
addEventHandler("onClientRaceCountdown", root, onCountdown)
addCommandHandler("soundvolume", onSoundVolumeCmd, false, false)
