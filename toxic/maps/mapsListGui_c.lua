addEvent('onClientDisplayVotenextGuiReq', true)
addEvent('onVotenextReq', true)
addEvent('onClientDisplayNextMapGuiReq', true)
addEvent('onAddMapToQueueReq', true)
addEvent('onClientDisplayChangeMapGuiReq', true)
addEvent('onChangeMapReq', true)
addEvent('onClientMapStarting')

local g_GuiList = {}
local g_MapList = false

local function MlstUpdateList(gui)
	local prof = DbgPerf()
	guiGridListClear(gui.list)
	
	-- Disable sorting temporary (it breaks row identifiers and makes update much slower)
	local sortDir = guiGetProperty(gui.list, 'SortDirection')
	guiSetProperty(gui.list, 'SortDirection', 'None')
	
	local pattern = guiGetText(gui.searchEdit):lower()
	
	for resName, data in pairs(g_MapList) do
		local mapName, mapAuthor = data[1], data[2]
		if(mapName:lower():find(pattern, 1, true) or mapAuthor:lower():find(pattern, 1, true)) then
			local row = guiGridListAddRow(gui.list)
			local played = data[3]
			assert(data[4]) -- bad argument #1 to 'format' (number expected, got nil)
			local rating = ('%.1f'):format(data[4])
			
			guiGridListSetItemText(gui.list, row, 1, mapName, false, false)
			guiGridListSetItemText(gui.list, row, 2, mapAuthor, false, false)
			guiGridListSetItemText(gui.list, row, 3, played, false, true)
			guiGridListSetItemText(gui.list, row, 4, rating, false, true)
			guiGridListSetItemData(gui.list, row, 1, resName)
		end
	end
	
	-- Reenable sorting
	guiSetProperty(gui.list, 'SortDirection', sortDir)
	prof:cp('MlstUpdateList')
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

local function MlstClose()
	local wnd = getElementParent(source)
	local gui = g_GuiList[wnd]
	assert(gui)
	
	gui.cb(false)
	gui:destroy()
	
	showCursor(false)
end

local function MlstResize()
	local gui = g_GuiList[source]
	assert(gui)
	
	local w, h = guiGetSize(source, false)
	
	guiSetSize(gui.list, w - 20, h - 70 - 45, false)
	guiSetPosition(gui.close_btn, w - 80 - 10, h - 25 - 10, false)
	if(gui.accept_btn) then
		guiSetPosition(gui.accept_btn, w - 200, h - 25 - 10, false)
	end
end

local function MlstAccept()
	local wnd = getElementParent(source)
	local gui = g_GuiList[wnd]
	assert(gui)
	
	local row = guiGridListGetSelectedItem(gui.list)
	if(row ~= -1 ) then
		local data = guiGridListGetItemData(gui.list, row, 1)
		gui.cb(data)
		gui:destroy()
		
		showCursor(false)
	end
end

local function MlstOnElementDestroy()
	g_GuiList[source] = nil
end

function MlstDisplay(title, btnName, callback)
	if(not g_MapList) then
		g_MapList = {}
		RPC('getMapListRPC'):onResult(MlstOnMapList):exec()
	end
	
	local gui = GUI.create('mapsList')
	gui.cb = callback
	
	guiSetText(gui.wnd, title)
	guiSetText(gui.titleLabel, title)
	
	addEventHandler('onClientElementDestroy', gui.wnd, MlstOnElementDestroy, false)
	addEventHandler('onClientGUIChanged', gui.searchEdit, MlstOnPatternChange, false)
	addEventHandler('onClientGUIDoubleClick', gui.list, MlstAccept, false)
	
	if(btnName) then
		guiSetText(gui.acceptBtn, btnName)
		addEventHandler('onClientGUIClick', gui.acceptBtn, MlstAccept, false)
	else
		guiSetVisible(gui.acceptBtn, false)
	end
	
	addEventHandler('onClientGUIClick', gui.closeBtn, MlstClose, false)
	
	MlstUpdateList(gui)
	
	g_GuiList[gui.wnd] = gui
	guiBringToFront(gui.searchEdit)
	showCursor(true)
	
	return gui.wnd
end

local function MlstOnMapStart(mapInfo)
	if(not g_MapList or type(mapInfo) ~= 'table') then return end
	
	local resName, mapName = mapInfo.resname, mapInfo.name
	local mapAuthor = mapInfo.author or ''
	
	if(g_MapList[resName]) then
		g_MapList[resName][1] = mapName
		g_MapList[resName][2] = mapAuthor
		g_MapList[resName][3] = g_MapList[resName][3] + 1
	else
		g_MapList[resName] = {mapName, mapAuthor, 1, 0}
	end
	
	for wnd, gui in pairs(g_GuiList) do
		MlstUpdateList(gui)
	end
end

local function DisplayVotenextGui()
	MlstDisplay("Select your candidate for next map", "Votenext", function(res_name)
		if(res_name) then
			triggerServerEvent('onVotenextReq', g_ResRoot, res_name)
		end
	end)
end

local function DisplayNextMapGui(is_next)
	MlstDisplay("Select next map", "Add to queue", function(res_name)
		if(res_name) then
			triggerServerEvent('onAddMapToQueueReq', g_ResRoot, res_name)
		end
	end)
end

local function DisplayChangeMapGui()
	MlstDisplay("Change current map", "Change map", function(res_name)
		if(res_name) then
			triggerServerEvent('onChangeMapReq', g_ResRoot, res_name)
		end
	end)
end

addEventHandler('onClientDisplayVotenextGuiReq', g_ResRoot, DisplayVotenextGui)
addEventHandler('onClientDisplayNextMapGuiReq', g_ResRoot, DisplayNextMapGui)
addEventHandler('onClientDisplayChangeMapGuiReq', g_ResRoot, DisplayChangeMapGui)
addEventHandler('onClientMapStarting', g_Root, MlstOnMapStart)
