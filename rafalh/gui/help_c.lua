-- INCLUDES
#include "include/internal_events.lua"

-- VARIABLES
local g_Commands
local g_HelpTab
local g_SearchEdit
local g_CmdList

-- CUSTOM EVENTS
addEvent ( "onCommandsListReq", true )
addEvent ( "onClientCommandsList", true )

-- FUNCTIONS
local function HlpUpdateList ()
	if ( not g_CmdList or not g_Commands ) then return end
	
	guiGridListClear ( g_CmdList )
	
	local text = guiGetText ( g_SearchEdit )
	local pattern = text:lower ()
	
	for i, cmd in ipairs ( g_Commands ) do
		local cmd_name_lower = cmd[1]:lower ()
		local cmd_descr_lower = ( cmd[2] or "" ):lower ()
		if ( pattern == "" or cmd_name_lower:find ( pattern, 1, true ) or cmd_descr_lower:find ( pattern, 1, true ) ) then
			local row = guiGridListAddRow ( g_CmdList )
			guiGridListSetItemText ( g_CmdList, row, 1, cmd[1], false, false )
			guiGridListSetItemText ( g_CmdList, row, 2, cmd[2] or "", false, false )
		end
	end
end

local function HlpCmdList ( commands )
	--g_Commands = commands
	--HlpUpdateList ()
end

local function HlpCreateGui ()
	local w, h = guiGetSize ( g_HelpTab, false )
	local y = 10
	
	local title = guiCreateLabel ( 10, y, w - 20, 15, "Controls", false, g_HelpTab )
	guiSetFont(title, "default-bold-small")
	local userPanelKey = getKeyBoundToCommand("UserPanel")
	local statsPanelKey = getKeyBoundToCommand("StatsPanel")
	local invKey = getKeyBoundToCommand("UserInventory")
	local mapInfoKey = getKeyBoundToCommand("MapInfoGui")
	guiCreateLabel(10, y + 1*15, w - 20, 15, MuiGetMsg("Press %s to show Statistics Panel."):format(statsPanelKey), false, g_HelpTab)
	guiCreateLabel(10, y + 2*15, w - 20, 15, MuiGetMsg("Press %s to show User Panel."):format(userPanelKey), false, g_HelpTab)
	guiCreateLabel(10, y + 3*15, w - 20, 15, MuiGetMsg("Press %s to show User Items."):format(invKey), false, g_HelpTab)
	guiCreateLabel(10, y + 4*15, w - 20, 15, MuiGetMsg("Press %s to show Map Info."):format(mapInfoKey), false, g_HelpTab)
	y = y + 5*15 + 10
	
	local title = guiCreateLabel ( 10, y, w - 20, 15, "Commands", false, g_HelpTab )
	guiSetFont ( title, "default-bold-small" )
	guiCreateLabel ( 10, y + 16, 50, 15, "Search:", false, g_HelpTab )
	g_SearchEdit = guiCreateEdit ( 60, y + 15, 150, 20, "", false, g_HelpTab )
	addEventHandler ( "onClientGUIChanged", g_SearchEdit, HlpUpdateList, false )
	g_CmdList = guiCreateGridList ( 10, y + 40, w - 20, h - ( y + 40 ) - 10, false, g_HelpTab )
	guiGridListAddColumn ( g_CmdList, "Command", 0.2 )
	guiGridListAddColumn ( g_CmdList, "Description", 0.7 )
end

local function HlpTabShown ()
	--[[if ( not g_CmdList ) then
		HlpCreateGui ()
	end
	if ( not g_Commands ) then
		triggerServerEvent ( "onCommandsListReq", g_Me )
	end]]
end

local function HlpInit ()
	local hlmmgr = getResourceFromName ( "helpmanager" )
	if(hlmmgr) then
		g_HelpTab = call(hlmmgr, "addHelpTab", getThisResource(), true)
		guiSetText(g_HelpTab, "Rafalh Scripts System")
		
		addEventHandler("onClientGUITabSwitched", g_HelpTab, HlpTabShown)
		local tabPanel = getElementParent(g_HelpTab)
		if(not tabPanel) then outputDebugString("wtf", 2)
		else guiGetSelectedTab(tabPanel) end
		
		--[[if(guiGetSelectedTab(tabPanel) == g_HelpTab) then
			HlpTabShown()
		end]]
	end
end

--------------
-- Commands --
--------------

addInternalEventHandler ( $(EV_CLIENT_INIT), HlpInit )
addEventHandler ( "onClientCommandsList", g_Root, HlpCmdList )
