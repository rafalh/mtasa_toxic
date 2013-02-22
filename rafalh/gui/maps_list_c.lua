addEvent("onClientMapList", true )
addEvent("onMapListReq", true )
addEvent("onClientDisplayVotenextGuiReq", true )
addEvent("onVotenextReq", true )
addEvent("onClientDisplayNextMapGuiReq", true )
addEvent("onAddMapToQueueReq", true )
addEvent("onClientDisplayChangeMapGuiReq", true )
addEvent("onChangeMapReq", true )

local g_GuiList = {}
local g_MapList = false

local function MlstUpdateList(gui)
	guiGridListClear(gui.list)
	
	local pattern = guiGetText(gui.search_edit):lower()
	
	for resName, data in pairs(g_MapList) do
		local mapName, mapAuthor = data[1], data[2]
		if(mapName:lower():find(pattern, 1, true) or mapAuthor:lower():find(pattern, 1, true)) then
			local row = guiGridListAddRow(gui.list)
			local played = data[3]
			local rating = ("%.1f"):format(data[4])
			guiGridListSetItemText(gui.list, row, 1, mapName, false, false)
			guiGridListSetItemText(gui.list, row, 2, mapAuthor, false, false)
			guiGridListSetItemText(gui.list, row, 3, played, false, true)
			guiGridListSetItemText(gui.list, row, 4, rating, false, true)
			guiGridListSetItemData(gui.list, row, 1, resName)
		end
	end
end

local function MlstOnMapList(mapList)
	g_MapList = mapList
	
	for wnd, gui in pairs(g_GuiList) do
		MlstUpdateList(gui)
	end
end

local function MlstOnPatternChange()
	local wnd = getElementParent(source)
	local gui = g_GuiList[wnd]
	assert(gui)
	
	MlstUpdateList(gui)
end

local function MlstClose ()
	local wnd = getElementParent ( source )
	local gui = g_GuiList[wnd]
	assert ( gui )
	
	destroyElement ( wnd )
	gui.cb ( false )
	
	guiSetInputEnabled ( false )
end

local function MlstResize ()
	local gui = g_GuiList[source]
	assert ( gui )
	
	local w, h = guiGetSize ( source, false )
	
	guiSetSize ( gui.list, w - 20, h - 70 - 45, false )
	guiSetPosition ( gui.close_btn, w - 80 - 10, h - 25 - 10, false )
	if ( gui.accept_btn ) then
		guiSetPosition ( gui.accept_btn, w - 200, h - 25 - 10, false )
	end
end

local function MlstAccept ()
	local wnd = getElementParent ( source )
	local gui = g_GuiList[wnd]
	assert ( gui )
	
	local row = guiGridListGetSelectedItem ( gui.list )
	if ( row ~= -1 ) then
		local data = guiGridListGetItemData ( gui.list, row, 1 )
		destroyElement ( gui.wnd )
		gui.cb ( data )
		
		guiSetInputEnabled ( false )
	end
end

function MlstDisplay ( title, btn_name, callback )
	if ( not g_MapList ) then
		g_MapList = {}
		triggerServerEvent ( "onMapListReq", g_ResRoot )
	end
	
	local gui = { cb = callback }
	
	local w, h = 480, 400
	local x, y = ( g_ScreenSize[1] - w ) / 2, ( g_ScreenSize[2] - h ) / 2
	gui.wnd = guiCreateWindow ( x, y, w, h, title, false )
	addEventHandler ( "onClientGUISize", gui.wnd, MlstResize, false )
	
	guiCreateLabel ( 10, 20, w - 20, 15, title, false, gui.wnd )
	
	guiCreateLabel ( 10, 40, 50, 15, "Search:", false, gui.wnd )
	gui.search_edit = guiCreateEdit ( 60, 40, 150, 20, "", false, gui.wnd )
	addEventHandler ( "onClientGUIChanged", gui.search_edit, MlstOnPatternChange, false )
	
	gui.list = guiCreateGridList ( 10, 70, w - 20, h - 70 - 45, false, gui.wnd )
	guiGridListAddColumn ( gui.list, "Map name", 0.5 )
	guiGridListAddColumn ( gui.list, "Author", 0.2 )
	guiGridListAddColumn ( gui.list, "Played", 0.1 )
	guiGridListAddColumn ( gui.list, "Map rating", 0.1 )
	addEventHandler ( "onClientGUIDoubleClick", gui.list, MlstAccept, false )
	MlstUpdateList ( gui )
	
	if ( btn_name ) then
		gui.accept_btn = guiCreateButton ( w - 200, h - 25 - 10, 100, 25, btn_name, false, gui.wnd )
		addEventHandler ( "onClientGUIClick", gui.accept_btn, MlstAccept, false )
	end
	
	local close_btn_name = accept_btn and "Cancel" or "Close"
	gui.close_btn = guiCreateButton ( w - 80 - 10, h - 25 - 10, 80, 25, close_btn_name, false, gui.wnd )
	addEventHandler ( "onClientGUIClick", gui.close_btn, MlstClose, false )
	
	g_GuiList[gui.wnd] = gui
	guiBringToFront ( gui.search_edit )
	guiSetInputEnabled ( true )
	
	return gui.wnd
end

local function MlstOnElementDestroy()
	if(not source) then
		outputDebugString("source == "..tostring(source).."...", 2)
	else
		g_GuiList[source] = nil
	end
end

local function MlstOnMapStart ( map_info )
	if ( not g_MapList or type(map_info) ~= "table" ) then return end
	
	if ( not g_MapList[map_info.resname] ) then
		g_MapList[map_info.resname] = { "", 0, 0 }
	end
	
	g_MapList[map_info.resname][1] = map_info.name
	g_MapList[map_info.resname][3] = g_MapList[map_info.resname][3] + 1
	
	for wnd, gui in pairs ( g_GuiList ) do
		MlstUpdateList ( gui )
	end
end

local function DisplayVotenextGui ()
	MlstDisplay ( "Select your candidate for next map", "Votenext", function ( res_name )
		if ( res_name ) then
			triggerServerEvent ( "onVotenextReq", g_ResRoot, res_name )
		end
	end )
end

local function DisplayNextMapGui ( is_next )
	MlstDisplay ( "Select next map", "Add to queue", function ( res_name )
		if ( res_name ) then
			triggerServerEvent ( "onAddMapToQueueReq", g_ResRoot, res_name )
		end
	end )
end

local function DisplayChangeMapGui ()
	MlstDisplay ( "Change current map", "Change map", function ( res_name )
		if ( res_name ) then
			triggerServerEvent ( "onChangeMapReq", g_ResRoot, res_name )
		end
	end )
end

addEventHandler ( "onClientMapList", g_ResRoot, MlstOnMapList )
addEventHandler ( "onClientElementDestroy", g_Root, MlstOnElementDestroy )
addEventHandler ( "onClientDisplayVotenextGuiReq", g_ResRoot, DisplayVotenextGui )
addEventHandler ( "onClientDisplayNextMapGuiReq", g_ResRoot, DisplayNextMapGui )
addEventHandler ( "onClientDisplayChangeMapGuiReq", g_ResRoot, DisplayChangeMapGui )
addEventHandler ( "onClientMapStarting", g_Root, MlstOnMapStart )
