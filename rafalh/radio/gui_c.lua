local g_Panel = false
local g_RadioImg, g_RadioName
local g_VolumeImg, g_VolumeBar
local g_List, g_TurnOffBtn
local g_Sound, g_Url, g_Volume = false, false, 100
local g_Muted, g_Filter = false, ""
local g_IgnoreFilterChange = true
local g_LastWarning = 0
local g_Channels = false

local RadioPanel = {
	name = "Radio",
	img = "radio/img/icon.png",
	tooltip = "Listen to internet radio",
}

local function loadChannels()
	local channels = {}
	local node, i = xmlLoadFile("conf/radio.xml"), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, "channel", i)
			if(not subnode) then break end
			i = i + 1
			
			local ch = {}
			ch.name = xmlNodeGetAttribute(subnode, "name")
			ch.img = xmlNodeGetAttribute(subnode, "img")
			ch.url = xmlNodeGetValue(subnode)
			assert(ch.name and ch.url)
			
			table.insert(channels, ch)
		end
		
		xmlUnloadFile(node)
	else
		outputDebugString("Failed to load radio channnels list", 2)
	end
	
	table.sort(channels, function(ch1, ch2) return ch1.name < ch2.name end)
	
	return channels
end

local function startRadio(url)
	assert(not g_Sound)
	setRadioChannel(0)
	
	g_Url = url
	
	if(not g_Muted) then
		g_Sound = playSound(url, true)
		if(g_Sound) then
			setSoundVolume(g_Sound, g_Volume / 100)
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
	stopRadio()
	
	local ch = g_Channels[i]
	Settings.radioChannel = ch.url
	
	guiSetText(g_RadioName, ch.name)
	if(ch.img) then
		guiStaticImageLoadImage(g_RadioImg, "radio/img/channels/"..ch.img)
	else
		guiStaticImageLoadImage(g_RadioImg, "img/no_img.png")
	end
	guiSetVisible(g_TurnOffBtn, true)
	g_List:setActiveItem(i)
end

local function setMuted(muted)
	if(g_Muted == muted) then return end
	g_Muted = muted
	
	if(g_VolumeImg) then
		guiStaticImageLoadImage(g_VolumeImg, g_Muted and "radio/img/muted.png" or "radio/img/volume.png")
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
	Settings.radioChannel = ""
	
	g_List:setActiveItem(false)
	stopRadio()
	guiSetText(g_RadioName, "Select radio channel")
	guiStaticImageLoadImage(g_RadioImg, "img/no_img.png")
	
end

local function onFilterFocus()
	if(g_Filter == "") then
		guiSetText(g_SearchBox, "")
	end
	g_IgnoreFilterChange = false
end

local function onFilterBlur()
	g_IgnoreFilterChange = true
	if(g_Filter == "") then
		guiSetText(g_SearchBox, MuiGetMsg("Search..."))
	end
end

local function onFilterChange()
	if(g_IgnoreFilterChange) then return end
	g_Filter = guiGetText(source)
	g_List:setFilter(g_Filter)
end

local function createGui(panel)
	g_Panel = panel
	local w, h = guiGetSize(panel, false)
	
	g_RadioImg = guiCreateStaticImage(10, 10, 48, 48, "img/no_img.png", false, panel)
	g_RadioName = guiCreateLabel(65, 10, w - 75, 15, "Select radio channel", false, panel)
	guiSetFont(g_RadioName, "default-bold-small")
	
	g_VolumeImg = guiCreateStaticImage(65, 30, 24, 24, "radio/img/volume.png", false, panel)
	addEventHandler("onClientGUIClick", g_VolumeImg, onVolumeClick, false)
	g_VolumeBar = guiCreateScrollBar(95, 32, w - 105, 20, true, false, panel)
	guiScrollBarSetScrollPosition(g_VolumeBar, g_Volume)
	addEventHandler("onClientGUIScroll", g_VolumeBar, onVolumeChange)
	
	g_SearchBox = guiCreateEdit(10, 65, 150, 25, MuiGetMsg("Search..."), false, panel)
	addEventHandler("onClientGUIFocus", g_SearchBox, onFilterFocus, false)
	addEventHandler("onClientGUIBlur", g_SearchBox, onFilterBlur, false)
	addEventHandler("onClientGUIChanged", g_SearchBox, onFilterChange, false)
	
	g_TurnOffBtn = guiCreateButton(w - 110, 65, 100, 25, "Turn off", false, panel)
	guiSetVisible(g_TurnOffBtn, g_Sound and true)
	addEventHandler("onClientGUIClick", g_TurnOffBtn, onTurnOffClick, false)
	
	g_Channels = loadChannels ()
	
	g_List = ListView.create({10, 100}, {w - 20, h - 140}, panel)
	g_List.onClickHandler = onChannelClick
	
	for i, ch in ipairs(g_Channels) do
		local imgPath = ch.img and "radio/img/channels/"..ch.img or "img/no_img.png"
		g_List:addItem(ch.name, imgPath, i)
		
		if(ch.url == g_Url) then
			g_List:setActiveItem(i)
			guiSetText(g_RadioName, ch.name)
			guiStaticImageLoadImage(g_RadioImg, imgPath)
		end
	end
	
	local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
	addEventHandler("onClientGUIClick", btn, UpBack, false)
end

function RadioPanel.onShow(panel)
	if(not g_Panel) then
		g_Panel = panel
		createGui(panel)
	end
end

function RadioPanel.onHide()
	Settings.save()
end

local function onRadioSwitch ( channel )
	if(g_Sound and channel ~= 0) then
		cancelEvent ()
		
		local ticks = getTickCount ()
		if(ticks - g_LastWarning > 3000) then
			outputChatBox("Disable online radio before using ingame radio (you can do it in User Panel)!", 255, 0, 0)
			g_LastWarning = ticks
		end
	end
end

local function checkSounds ()
	if(not g_Sound or g_Volume == 0) then return end
	
	-- find long sounds
	local found = false
	--outputDebugString ( "sounds "..#getElementsByType ( "sound" )..":", 3 )
	for i, sound in ipairs(getElementsByType("sound")) do
		--outputDebugString ( i.." "..getSoundLength ( sound ).." "..getSoundVolume ( sound ), 3 )
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
		outputChatBox("Radio has been temporary disabled because other music source has been detected!", 255, 0, 0)
	elseif(real_volume == 0 and not found) then
		setSoundVolume(g_Sound, g_Volume / 100)
	end
end

local function initRadio()
	setTimer(checkSounds, 1000, 0)
end

UpRegister(RadioPanel)
addEventHandler("onClientPlayerRadioSwitch", g_Me, onRadioSwitch)
addEventHandler("onClientResourceStart", g_ResRoot, initRadio)

Settings.register
{
	name = "radioChannel",
	default = "",
	cast = tostring,
	onChange = function(oldVal, newVal)
		if(newVal ~= "" and not g_Muted) then
			startRadio(newVal)
		else
			stopRadio()
		end
	end,
}

Settings.register
{
	name = "radioVolume",
	default = 100,
	cast = tonumber,
	onChange = function(oldVal, newVal)
		if(g_Sound) then
			setSoundVolume(g_Sound, newVal / 100)
		end
		setMuted(newVal == 0)
	end,
}
