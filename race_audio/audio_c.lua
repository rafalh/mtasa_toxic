local g_SoundVolume = 0.5
local g_UnmuteRadioTimer = false
local g_CountdownValue = 0

addEvent("race_audio.onPlayReq", true)
addEvent("onClientPlayerOutOfTime", true)
addEvent("onClientPlayerHitPickup", true)
addEvent("onClientPlayerReachCheckpoint", true)
addEvent("race.onCountdownStart")

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

local function updateCountdown()
	if(g_CountdownValue > 0) then
		playAudio("countdown.mp3")
	else
		playAudio("go.mp3")
	end
	g_CountdownValue = g_CountdownValue - 1
end

local function onCountdownStart(name, sec)
	sec = math.floor(sec)
	if(name == "race") then
		g_CountdownValue = sec
		updateCountdown()
		setTimer(updateCountdown, 1000, sec)
	end
end

function setRaceAudioVolume(val)
	val = math.min(math.max(tonumber(val), 0), 1)
	if(val) then
		g_SoundVolume = val
		return true
	else
		return false
	end
end

local function onRaceVolumeCmd(cmd, value)
	value = math.min(math.max(tonumber(value), 0), 100)
	if(value) then
		g_SoundVolume = value/100
		outputChatBox("Race audio volume has been set to "..value.."%", 255, 255, 255)
	else
		outputChatBox("Usage: /"..cmd.." n", 255, 255, 255)
	end
end

addEventHandler("race_audio.onPlayReq", root, playAudio)
addEventHandler("onClientResourceStart", resourceRoot, onResStart)
addEventHandler("onClientPlayerOutOfTime", root, onOutOfTime)
addEventHandler("onClientPlayerHitPickup", localPlayer, onHitPickup)
addEventHandler("onClientPlayerReachCheckpoint", localPlayer, onReachCheckpoint)
addEventHandler("onClientPlayerFinish", localPlayer, onFinish)
addEventHandler("race.onCountdownStart", root, onCountdownStart)
addCommandHandler("racevolume", onRaceVolumeCmd, false, false)
