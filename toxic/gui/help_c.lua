-- INCLUDES
#include 'include/internal_events.lua'

-- VARIABLES
local g_Commands
local g_LoadingCmdList = false
local g_GuiParent, g_SearchEdit, g_CmdList
local g_HelpMgrRes = Resource('helpmanager')

-- FUNCTIONS
local function HlpUpdateList()
	if(not g_CmdList or not g_Commands) then return end
	
	guiGridListClear(g_CmdList)
	
	local text = guiGetText(g_SearchEdit)
	local pattern = text:lower()
	
	for i, cmd in ipairs(g_Commands) do
		local cmdNameLower = cmd[1]:lower()
		local cmdDescLower = (cmd[2] or ''):lower()
		if(pattern == '' or cmdNameLower:find(pattern, 1, true) or cmdDescLower:find(pattern, 1, true)) then
			local row = guiGridListAddRow(g_CmdList)
			guiGridListSetItemText(g_CmdList, row, 1, cmd[1], false, false)
			guiGridListSetItemText(g_CmdList, row, 2, cmd[2] or '', false, false)
		end
	end
end

local function HlpCmdList(commands)
	g_Commands = commands
	HlpUpdateList()
end

local function HlpCreateGui(parent, x, y, w, h)
	local title = guiCreateLabel(x, y, w, 15, "Controls", false, parent)
	guiSetFont(title, 'default-bold-small')
	local userPanelKey = getKeyBoundToCommand('UserPanel')
	local statsPanelKey = getKeyBoundToCommand('StatsPanel')
	local invKey = getKeyBoundToCommand('UserInventory')
	local mapInfoKey = getKeyBoundToCommand('MapInfoGui')
	guiCreateLabel(x, y + 1*15, w, 15, MuiGetMsg("Press %s to show Statistics Panel."):format(statsPanelKey), false, parent)
	guiCreateLabel(x, y + 2*15, w, 15, MuiGetMsg("Press %s to show User Panel."):format(userPanelKey), false, parent)
	guiCreateLabel(x, y + 3*15, w, 15, MuiGetMsg("Press %s to show User Items."):format(invKey), false, parent)
	guiCreateLabel(x, y + 4*15, w, 15, MuiGetMsg("Press %s to show Map Info."):format(mapInfoKey), false, parent)
	y = y + 5*15 + 10
	
	local title = guiCreateLabel(x, y, w, 15, "Commands", false, parent)
	guiSetFont(title, 'default-bold-small')
	guiCreateLabel(x, y + 16, 50, 15, "Search:", false, parent)
	g_SearchEdit = guiCreateEdit(x + 50, y + 15, 150, 20, '', false, parent)
	addEventHandler('onClientGUIChanged', g_SearchEdit, HlpUpdateList, false)
	g_CmdList = guiCreateGridList(x, y + 40, w, h - (y + 40), false, parent)
	guiGridListAddColumn(g_CmdList, "Command", 0.2)
	guiGridListAddColumn(g_CmdList, "Description", 0.7)
end

local function HlpLoadCmdList()
	if(not g_Commands and not g_LoadingCmdList) then
		g_LoadingCmdList = true
		RPC('CmdMgr.getCommandsForHelp'):onResult(HlpCmdList):exec()
	end
end

local function HlpTabShown()
	if(not g_CmdList) then
		local w, h = guiGetSize(g_GuiParent, false)
		HlpCreateGui(g_GuiParent, 10, 10, w - 20, h - 20)
	end
	HlpLoadCmdList()
end

local function HlpCloseWnd()
	guiSetVisible(g_GuiParent, false)
	showCursor(false)
end

local function HlpCreateWnd()
	local w, h = 500, 400
	local x, y = (g_ScreenSize[1]-w)/2, (g_ScreenSize[2]-h)/2
	g_GuiParent = guiCreateWindow(x, y, w, h, "Toxic Help", false)
	guiWindowSetSizable(g_GuiParent, false)
	
	local closeBtn = guiCreateButton(w - 90, h - 35, 80, 25, "Close", false, g_GuiParent)
	addEventHandler('onClientGUIClick', closeBtn, HlpCloseWnd, false)
	
	HlpCreateGui(g_GuiParent, 10, 25, w - 20, h - 45)
	HlpLoadCmdList()
end

local function HlpOpenWnd()
	if(not g_GuiParent) then
		HlpCreateWnd()
	else
		guiSetVisible(g_GuiParent, true)
	end
	
	showCursor(true)
	guiBringToFront(g_GuiParent)
end

local function HlpToggleWnd()
	if(g_GuiParent and guiGetVisible(g_GuiParent)) then
		HlpCloseWnd()
	else
		HlpOpenWnd()
	end
end

local function HlpInit()
	if(Settings.helpmgr and g_HelpMgrRes:isReady()) then
		g_GuiParent = g_HelpMgrRes:call('addHelpTab', getThisResource(), true)
		guiSetText(g_GuiParent, "Rafalh Scripts System")
		
		addEventHandler('onClientGUITabSwitched', g_GuiParent, HlpTabShown)
		local tabPanel = getElementParent(g_GuiParent)
		if(not tabPanel) then outputDebugString('No tab panel found', 2)
		else guiGetSelectedTab(tabPanel) end
		
		if(guiGetSelectedTab(tabPanel) == g_GuiParent) then
			HlpTabShown()
		end
	else
		bindKey('F9', 'down', HlpToggleWnd)
	end
end

--------------
-- Commands --
--------------

addInternalEventHandler($(EV_CLIENT_INIT), HlpInit)
