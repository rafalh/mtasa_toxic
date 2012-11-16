--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Gui = nil
local g_TopTypes = {
	{ "cash", "Cash", formatMoney },
	{ "points", "Points", formatNumber },
	{ "first", "Race - 1st", formatNumber },
	{ "second", "Race - 2nd", formatNumber },
	{ "third", "Race - 3rd", formatNumber },
	{ "dm", "DD/DM Played" },
	{ "dm_wins", "DD/DM Wins" },
	{ "bidlvl", "Bidlevel" }
}
local g_CurrentTop = 1
local g_IdCol, g_NameCol, g_DataCol

local TopsPanel = {
	name = "Tops",
	img = "img/userpanel/leader_board.png",
}

--------------------------------
-- Local function definitions --
--------------------------------

local function onPrevTopClick ()
	if ( g_CurrentTop <= 1 ) then
		g_CurrentTop = tonumber ( #g_TopTypes )
	else
		g_CurrentTop = g_CurrentTop - 1
	end
	guiSetText ( g_Gui.toptype, "Top "..g_TopTypes[g_CurrentTop][2] )
	guiGridListClear ( g_Gui.list )
	guiGridListRemoveColumn ( g_Gui.list, g_DataCol )
	g_DataCol = guiGridListAddColumn( g_Gui.list, g_TopTypes[g_CurrentTop][2], 0.3 )
	
	triggerServerInternalEvent ( $(EV_SYNC_ONCE_REQUEST), g_Me, { tops = ( ( guiCheckBoxGetSelected ( g_Gui.checkbox ) and g_CurrentTop ) or -g_CurrentTop ) } )
end

local function onNextTopClick ()
	if ( g_CurrentTop >= #g_TopTypes ) then
		g_CurrentTop = 1
	else
		g_CurrentTop = g_CurrentTop + 1
	end
	guiSetText ( g_Gui.toptype, "Top "..g_TopTypes[g_CurrentTop][2] )
	guiGridListClear ( g_Gui.list )
	guiGridListRemoveColumn ( g_Gui.list, g_DataCol )
	g_DataCol = guiGridListAddColumn( g_Gui.list, g_TopTypes[g_CurrentTop][2], 0.3 )
	
	triggerServerInternalEvent ( $(EV_SYNC_ONCE_REQUEST), g_Me, { tops = ( ( guiCheckBoxGetSelected ( g_Gui.checkbox ) and g_CurrentTop ) or -g_CurrentTop ) } )
end

local function onCheckboxClick ()
	triggerServerInternalEvent ( $(EV_SYNC_ONCE_REQUEST), g_Me, { tops = ( ( guiCheckBoxGetSelected ( g_Gui.checkbox ) and g_CurrentTop ) or -g_CurrentTop ) } )
end

local function onDoubleClickPlayer ()
	local row, col = guiGridListGetSelectedItem ( g_Gui.list )
	local id = row and guiGridListGetItemData ( g_Gui.list, row, g_NameCol )
	if ( id ) then
		StCreatePlayerInfoWnd ( id )
	end
end

local function initGui ( tab )
	g_Gui = {}
	
	local w, h = guiGetSize ( tab, false )
	
	g_Gui.toptype = guiCreateLabel ( 40, 10, w - 80, 15, "Top "..g_TopTypes[1][2], false, tab  )
	guiLabelSetHorizontalAlign ( g_Gui.toptype, "center" )
	
	local btn = guiCreateButton ( 10, 10, 25, 25, "<", false, tab )
	addEventHandler ( "onClientGUIClick", btn, onPrevTopClick, false )
	
	btn = guiCreateButton ( w - 35, 10, 25, 25, ">", false, tab )
	addEventHandler ( "onClientGUIClick", btn, onNextTopClick, false )
	
	g_Gui.checkbox = guiCreateCheckBox ( 10, 40, w - 20, 15, "Players online only", false, false, tab )
	addEventHandler ( "onClientGUIClick", g_Gui.checkbox, onCheckboxClick, false )
	
	g_Gui.list = guiCreateGridList ( 10, 60, w - 20, h - 70, false, tab )
	-- disable sorting because it breaks adding rows (MTA 1.3)
	guiGridListSetSortingEnabled ( g_Gui.list, false )
	g_IdCol = guiGridListAddColumn( g_Gui.list, "#", 0.1 )
	g_NameCol = guiGridListAddColumn( g_Gui.list, "Player", 0.5 )
	g_DataCol = guiGridListAddColumn( g_Gui.list, g_TopTypes[1][2], 0.3 )
	addEventHandler ( "onClientGUIDoubleClick", g_Gui.list, onDoubleClickPlayer, false )
end

function TopsPanel.onShow ( tab )
	if ( not g_Gui ) then
		initGui ( tab )
	end
	
	local top_type = ( guiCheckBoxGetSelected ( g_Gui.checkbox ) and g_CurrentTop ) or -g_CurrentTop
	triggerServerInternalEvent ( $(EV_SYNC_ONCE_REQUEST), g_Me, { tops = top_type } )
end

local function onSync ( sync_tbl )
	if ( not g_Gui ) then return end
	local top_type = ( guiCheckBoxGetSelected ( g_Gui.checkbox ) and g_CurrentTop ) or -g_CurrentTop
	if ( not sync_tbl.tops or sync_tbl.tops[1] ~= top_type ) then return end
	
	local top = sync_tbl.tops[2]
	guiGridListClear ( g_Gui.list )
	
	local colors = { { 255, 255, 64 }, { 196, 196, 196 }, { 196, 96, 96 } }
	
	for i, data in ipairs ( top ) do
		local row = guiGridListAddRow ( g_Gui.list )
		
		guiGridListSetItemText ( g_Gui.list, row, g_IdCol, i, false, true )
		
		guiGridListSetItemText ( g_Gui.list, row, g_NameCol, data.name, false, false )
		guiGridListSetItemData ( g_Gui.list, row, g_NameCol, data.id )
		
		local val = data[g_TopTypes[g_CurrentTop][1]]
		if ( g_TopTypes[g_CurrentTop][3] ) then
			val = g_TopTypes[g_CurrentTop][3] ( val )
		end
		
		guiGridListSetItemText ( g_Gui.list, row, g_DataCol, tostring ( val ), false, false )
		
		if ( colors[i] ) then
			local r, g, b = colors[i][1], colors[i][2], colors[i][3]
			guiGridListSetItemColor ( g_Gui.list, row, g_IdCol, r, g, b )
			guiGridListSetItemColor ( g_Gui.list, row, g_NameCol, r, g, b )
			guiGridListSetItemColor ( g_Gui.list, row, g_DataCol, r, g, b )
		end
	end
end

----------------------
-- Global variables --
----------------------

UpRegister ( TopsPanel )

------------
-- Events --
------------

addInternalEventHandler ( $(EV_SYNC), onSync )
