local g_Root = getRootElement ()
local g_ResRoot = getResourceRootElement ()
local g_Me = getLocalPlayer ()
local g_MusicEnabled = false
local g_Sound = false
local g_SoundUrl = false

g_AutoStart = true

addEvent ( "onClientStartMusicReq", true )
addEvent ( "onClientStopMusicReq", true )
addEvent ( "onPlayerReady", true )

local function onRadioSwitch ( channel )
	if ( channel ~= 0 ) then
		cancelEvent ()
	end
end

local function onPlayerVehicleEnter ()
    setRadioChannel ( 0 )
end

local function invalidateSound()
	if(g_Sound) then
		destroyElement(g_Sound)
		g_Sound = false
	end
end

local function setupSound()
	assert(not g_Sound)
	
	if(g_SoundUrl) then
		g_Sound = playSound ( g_SoundUrl, true )
		if ( not g_Sound ) then
			outputDebugString ( "playSound failed!", 2 )
		end
	end
end

local function setMusicEnabled(enabled)
	if(not g_SoundUrl) then return end
	
	if(not g_Sound and enabled) then
		setupSound()
	end
	
	if(g_MusicEnabled == enabled) then return end
	
	if(not enabled) then
		if(g_Sound) then
			setSoundVolume ( g_Sound, 0 )
		end
		g_MusicEnabled = false
		removeEventHandler ( "onClientPlayerRadioSwitch", g_Root, onRadioSwitch )
		removeEventHandler ( "onClientPlayerVehicleEnter", g_Me, onPlayerVehicleEnter )
	else
		setSoundVolume ( g_Sound, 1 )
		g_MusicEnabled = true
		setRadioChannel ( 0 )
		addEventHandler ( "onClientPlayerRadioSwitch", g_Root, onRadioSwitch )
		addEventHandler ( "onClientPlayerVehicleEnter", g_Me, onPlayerVehicleEnter )
	end
end

local function toggleMusic ()
	setMusicEnabled(not g_MusicEnabled)
end

local function startMusicReq ( url )
	--outputDebugString ( "startMusicReq "..url, 3 )
	
	g_SoundUrl = url
	invalidateSound()
	
	local msg = "Press 'M' to toggle the music On/Off"
	if(getElementData(g_Me, "lang") == "pl") then
		msg = "Wciśnij 'M' by włączyć/wyłączyć muzykę"
	end
	outputChatBox(msg, 255, 255, 255)
	
	setMusicEnabled(g_AutoStart)
end

local function stopMusicReq ()
	g_SoundUrl = false
	invalidateSound()
end

local function init ()
	triggerServerEvent ( "onPlayerReady", g_ResRoot )
end

addCommandHandler ( "music", toggleMusic )
bindKey ( "m", "down", toggleMusic )

addEventHandler ( "onClientStartMusicReq", g_ResRoot, startMusicReq )
addEventHandler ( "onClientStopMusicReq", g_ResRoot, stopMusicReq )
addEventHandler ( "onClientResourceStart", g_ResRoot, init )
