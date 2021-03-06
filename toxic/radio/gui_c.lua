local MEDIA_RES_NAME = 'txmedia'

local g_Panel = false
local g_RadioImg, g_RadioName
local g_VolumeImg, g_VolumeBar
local g_List, g_TurnOffBtn
local g_Sound, g_Url = false, false
local g_Muted, g_Filter = false, ''
local g_IgnoreFilterChange = true
local g_LastWarning = 0
local g_Channels = false

local RadioPanel = {
	name = "Radio",
	img = 'radio/img/icon.png',
	tooltip = "Listen to internet radio",
}

local function startRadio(url)
	assert(not g_Sound)
	setRadioChannel(0)
	
	g_Url = url
	
	if(not g_Muted) then
		g_Sound = playSound(url, true)
		if(g_Sound) then
			setSoundVolume(g_Sound, Settings.radioVolume / 100)
		end
	end
	
	AchvActivate("Try built-in radio")
end

local function stopRadio()
	if(g_Sound) then
		stopSound(g_Sound)
		g_Sound = false
	end
end

local function onChannelClick(i)
	local ch = g_Channels[i]
	Settings.radioChannel = ch.url
	
	guiSetText(g_RadioName, ch.name)
	if(ch.img) then
		guiStaticImageLoadImage(g_RadioImg, ':'..MEDIA_RES_NAME..'/'..ch.img)
	else
		guiStaticImageLoadImage(g_RadioImg, 'img/no_img.png')
	end
	guiSetVisible(g_TurnOffBtn, true)
	g_List:setActiveItem(i)
end

local function setMuted(muted)
	if(g_Muted == muted) then return end
	g_Muted = muted
	
	if(g_VolumeImg) then
		guiStaticImageLoadImage(g_VolumeImg, g_Muted and 'radio/img/muted.png' or 'radio/img/volume.png')
	end
	
	if(g_Muted) then
		stopRadio()
	elseif(g_Url) then
		startRadio(g_Url)
	end
end

local function onVolumeChange()
	Settings.radioVolume = guiScrollBarGetScrollPosition(g_VolumeBar)
end

local function onVolumeClick()
	setMuted(not g_Muted)
end

local function onTurnOffClick()
	guiSetVisible(g_TurnOffBtn, false)
	Settings.radioChannel = ''
	
	g_List:setActiveItem(false)
	stopRadio()
	guiSetText(g_RadioName, "Select radio channel")
	guiStaticImageLoadImage(g_RadioImg, 'img/no_img.png')
	
end

local function onFilterFocus()
	if(g_Filter == '') then
		guiSetText(g_SearchBox, '')
	end
	g_IgnoreFilterChange = false
end

local function onFilterBlur()
	g_IgnoreFilterChange = true
	if(g_Filter == '') then
		guiSetText(g_SearchBox, MuiGetMsg("Search..."))
	end
end

local function onFilterChange()
	if(g_IgnoreFilterChange) then return end
	g_Filter = guiGetText(source)
	g_List:setFilter(g_Filter)
end

local function onChannelsList(channels)
	g_Channels = channels
	
	g_List:clear()
	for i, ch in ipairs(channels) do
		local imgPath = ch.img and ':'..MEDIA_RES_NAME..'/'..ch.img
		if(not imgPath or not fileExists(imgPath)) then
			imgPath = 'img/no_img.png'
		end
		
		g_List:addItem(ch.name, imgPath, i)
		
		if(ch.url == g_Url) then
			g_List:setActiveItem(i)
			guiSetText(g_RadioName, ch.name)
			guiStaticImageLoadImage(g_RadioImg, imgPath)
		end
	end
end

local function createGui(panel)
	g_Panel = panel
	local w, h = guiGetSize(panel, false)
	
	g_RadioImg = guiCreateStaticImage(10, 10, 48, 48, 'img/no_img.png', false, panel)
	g_RadioName = guiCreateLabel(65, 10, w - 75, 15, "Select radio channel", false, panel)
	guiSetFont(g_RadioName, 'default-bold-small')
	
	g_VolumeImg = guiCreateStaticImage(65, 30, 24, 24, 'radio/img/volume.png', false, panel)
	addEventHandler('onClientGUIClick', g_VolumeImg, onVolumeClick, false)
	g_VolumeBar = guiCreateScrollBar(95, 32, w - 105, 20, true, false, panel)
	guiScrollBarSetScrollPosition(g_VolumeBar, Settings.radioVolume)
	addEventHandler('onClientGUIScroll', g_VolumeBar, onVolumeChange, false)
	
	g_SearchBox = guiCreateEdit(10, 65, 150, 25, MuiGetMsg("Search..."), false, panel)
	addEventHandler('onClientGUIFocus', g_SearchBox, onFilterFocus, false)
	addEventHandler('onClientGUIBlur', g_SearchBox, onFilterBlur, false)
	addEventHandler('onClientGUIChanged', g_SearchBox, onFilterChange, false)
	
	g_TurnOffBtn = guiCreateButton(w - 110, 65, 100, 25, "Turn off", false, panel)
	guiSetVisible(g_TurnOffBtn, g_Sound and true)
	addEventHandler('onClientGUIClick', g_TurnOffBtn, onTurnOffClick, false)
	
	local listSize = {w - 20, h - 105}
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
		addEventHandler('onClientGUIClick', btn, UpBack, false)
		listSize[2] = listSize[2] - 35
	end
	
	g_List = ListView.create({10, 100}, listSize, panel, nil, nil, nil, true)
	g_List.onClickHandler = onChannelClick
	
	-- Get channels list from server
	RPC('Radio.getChannels'):onResult(onChannelsList):exec()
	g_Channels = {}
end

function RadioPanel.onShow(panel)
	if(not g_Panel) then
		g_Panel = panel
		createGui(panel)
	elseif(not g_Channels) then
		-- Get channels list from server
		RPC('Radio.getChannels'):onResult(onChannelsList):exec()
		g_Channels = {}
	end
end

function RadioPanel.onHide()
	Settings.save()
end

local function onRadioSwitch(channel)
	if(g_Sound and channel ~= 0) then
		cancelEvent()
		
		local ticks = getTickCount()
		if(ticks - g_LastWarning > 3000) then
			outputMsg(Styles.red, "Disable online radio before using in-game radio (you can do it in User Panel)!")
			g_LastWarning = ticks
		end
	end
end

local function checkSounds()
	if(not g_Sound or Settings.radioVolume == 0) then return end
	
	-- find long sounds
	local found = false
	--Debug.info('sounds '..#getElementsByType ( 'sound' )..':')
	for i, sound in ipairs(getElementsByType('sound')) do
		--Debug.info(i..' '..getSoundLength ( sound )..' '..getSoundVolume ( sound ))
		local len = getSoundLength ( sound )
		-- Note: streams has len == 0
		if ( sound ~= g_Sound and ( len > 10 or len == 0) and getSoundVolume ( sound ) > 0 ) then
			found = true
			break
		end
	end
	
	-- disable radio if map has music background
	local real_volume = getSoundVolume(g_Sound)
	if(real_volume and real_volume > 0 and found) then
		setSoundVolume(g_Sound, 0)
		outputMsg(Styles.red, "Radio has been temporary disabled because other music source has been detected!")
	elseif(real_volume == 0 and not found) then
		setSoundVolume(g_Sound, Settings.radioVolume / 100)
	end
end

local function onRadioChannelsChange()
	if(g_Panel and guiGetVisible(g_Panel)) then
		-- Get channels list from server
		RPC('Radio.getChannels'):onResult(onChannelsList):exec()
		g_Channels = {}
	else
		g_Channels = false
	end
end

addEvent('toxic.onRadioChannelsChange', true)

addInitFunc(function()
	UpRegister(RadioPanel)
	
	addEventHandler('onClientPlayerRadioSwitch', g_Me, onRadioSwitch)
	addEventHandler('toxic.onRadioChannelsChange', g_ResRoot, onRadioChannelsChange)
	
	setTimer(checkSounds, 1000, 0)
end)

addInitFunc(function()
	Settings.register
	{
		name = 'radioChannel',
		default = '',
		cast = tostring,
		onChange = function(oldVal, newVal)
			stopRadio()
			if (newVal ~= '' and not g_Muted) then
				startRadio(newVal)
			end
		end,
	}

	Settings.register
	{
		name = 'radioVolume',
		default = 100,
		cast = tonumber,
		onChange = function(oldVal, newVal)
			if (g_Sound) then
				setSoundVolume(g_Sound, newVal / 100)
			end
			setMuted(newVal == 0)
		end,
	}
end, -2000)
