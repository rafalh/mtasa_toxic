local g_Wnd = false
local g_VolumeBar, g_VolumeLabel, g_List
local g_CurrentRow = false
local g_Sound, g_Volume = false, 100
local g_LastWarning = 0

local RadioPanel = {
	name = "Radio",
	img = "img/userpanel/music.png",
}

local function loadChannels ()
	local channels = {}
	local node, i = xmlLoadFile ( "conf/radio.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "channel", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local ch = {}
			ch.name = xmlNodeGetAttribute ( subnode, "name" )
			ch.longname = xmlNodeGetAttribute ( subnode, "longname" )
			ch.url = xmlNodeGetValue ( subnode )
			assert ( ch.name and ch.url )
			
			table.insert ( channels, ch )
		end
		
		xmlUnloadFile ( node )
	end
	
	table.sort ( channels, function ( ch1, ch2 ) return ch1.name < ch2.name end )
	
	return channels
end

local function startRadio ( url )
	setRadioChannel ( 0 )
	
	g_Sound = playSound ( url, true )
	if ( g_Sound ) then
		setSoundVolume ( g_Sound, g_Volume / 100 )
		
		g_ClientSettings.radio_channel = url
	end
end

local function onDoubleClickChannel ()
	local row, col = guiGridListGetSelectedItem ( g_List )
	local url = row and guiGridListGetItemData ( g_List, row, 1 )
	if ( url ) then
		if ( g_Sound ) then
			stopSound ( g_Sound )
		end
		
		startRadio ( url )
		
		if ( g_CurrentRow ) then
			guiGridListSetItemColor ( g_List, g_CurrentRow, 1, 255, 255, 255 )
		end
		g_CurrentRow = row
		guiGridListSetItemColor ( g_List, g_CurrentRow, 1, 255, 255, 160 )
		
		guiCheckBoxSetSelected ( g_RadioCheckbox, true )
	end
end

local function onVolumeChange ()
	g_Volume = guiScrollBarGetScrollPosition ( g_VolumeBar )
	if ( g_Sound ) then
		setSoundVolume ( g_Sound, g_Volume / 100 )
		g_ClientSettings.radio_volume = g_Volume
	end
	guiSetText ( g_VolumeLabel, MuiGetMsg ( "Volume: %u%%" ):format ( g_Volume ) )
end

local function onCheckboxClick ()
	if ( not guiCheckBoxGetSelected ( g_RadioCheckbox ) and g_Sound ) then
		stopSound ( g_Sound )
		g_Sound = false
		if(g_CurrentRow) then
			guiGridListSetItemColor ( g_List, g_CurrentRow, 1, 255, 255, 255 )
		end
		
		g_ClientSettings.radio_channel = ""
	end
end

local function createGui ( parent )
	g_Wnd = parent
	local w, h = guiGetSize ( g_Wnd, false )
	
	g_RadioCheckbox = guiCreateCheckBox ( 10, 10, w - 20, 15, "Enable radio", true, false, g_Wnd )
	addEventHandler ( "onClientGUIClick", g_RadioCheckbox, onCheckboxClick, false )
	
	g_VolumeLabel = guiCreateLabel ( 10, 30, w - 20, 15, MuiGetMsg ( "Volume: %u%%" ):format ( g_Volume ), false, g_Wnd )
	guiCreateStaticImage ( 10, 48, 24, 24, "img/volume.png", false, g_Wnd )
	g_VolumeBar = guiCreateScrollBar ( 35, 50, w - 45, 20, true, false, g_Wnd )
	guiScrollBarSetScrollPosition ( g_VolumeBar, g_Volume )
	addEventHandler ( "onClientGUIScroll", g_VolumeBar, onVolumeChange )
	
	g_List = guiCreateGridList ( 10, 80, w - 20, h - 100, false, g_Wnd )
	addEventHandler ( "onClientGUIDoubleClick", g_List, onDoubleClickChannel, false )
	local col = guiGridListAddColumn( g_List, "Channel", 0.8 )
	local channels = loadChannels ()
	
	for i, ch in ipairs ( channels ) do
		local row = guiGridListAddRow ( g_List )
		guiGridListSetItemText ( g_List, row, col, ch.longname or ch.name, false, false )
		guiGridListSetItemData ( g_List, row, col, ch.url )
	end
end

function RadioPanel.onShow ( tab )
	if ( not g_Wnd ) then
		g_Wnd = tab
		createGui ( tab )
	end
end

function RadioPanel.onHide ()
	saveSettings ()
end

local function onRadioSwitch ( channel )
	if ( g_Sound and channel ~= 0 ) then
		cancelEvent ()
		
		local ticks = getTickCount ()
		if ( ticks - g_LastWarning > 3000 ) then
			outputChatBox ( "Disable online radio before using ingame radio (you can do it in User Panel)!", 255, 0, 0 )
			g_LastWarning = ticks
		end
	end
end

local function checkSounds ()
	if ( not g_Sound or g_Volume == 0 ) then return end
	
	-- find long sounds
	local found = false
	--outputDebugString ( "sounds "..#getElementsByType ( "sound" )..":", 3 )
	for i, sound in ipairs ( getElementsByType ( "sound" ) ) do
		--outputDebugString ( i.." "..getSoundLength ( sound ).." "..getSoundVolume ( sound ), 3 )
		local len = getSoundLength ( sound )
		-- Note: streams has len == 0
		if ( sound ~= g_Sound and ( len > 10 or len == 0) and getSoundVolume ( sound ) > 0 ) then
			found = true
			break
		end
	end
	
	-- disable radio if map has music background
	local real_volume = getSoundVolume ( g_Sound )
	if ( real_volume and real_volume > 0 and found ) then
		setSoundVolume ( g_Sound, 0 )
		outputChatBox ( "Radio has been temporary disabled because other music source has been detected!", 255, 0, 0 )
	elseif ( real_volume == 0 and not found ) then
		setSoundVolume ( g_Sound, g_Volume / 100 )
	end
end

local function initRadio ()
	setTimer ( checkSounds, 1000, 0 )
	
	g_Volume = math.min ( g_ClientSettings.radio_volume, 100 )
	if ( g_ClientSettings.radio_channel ~= "" ) then
		startRadio ( g_ClientSettings.radio_channel )
	end
end

UpRegister ( RadioPanel )
addEventHandler ( "onClientPlayerRadioSwitch", g_Me, onRadioSwitch )
addEventHandler ( "onClientResourceStart", g_ResRoot, initRadio )
