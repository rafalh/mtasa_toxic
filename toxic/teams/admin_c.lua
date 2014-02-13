local g_GUI = false
local g_CtxEdit
local TeamsAdmin = {}
TeamsAdmin.pathName = "Teams"

AdminPanel:addItem{
	name = "Teams",
	right = AccessRight('teams'),
	exec = function()
		TeamsAdmin:show()
		return true
	end,
}

local function updateRow(row, teamInfo)
	local tagOrGroup = teamInfo.tag == '' and teamInfo.aclGroup or teamInfo.tag
	local typeStr = teamInfo.aclGroup == '' and "Tag" or "ACL"
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo.name, false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.typeCol, typeStr, false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.tagCol, tagOrGroup, false, false)
	if(teamInfo.color) then
		guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.clrCol, teamInfo.color, false, false)
		local r, g, b = getColorFromString(teamInfo.color)
		if(r) then
			guiGridListSetItemColor(g_GUI.teamsList, row, g_GUI.clrCol, r, g, b)
		end
	end
	local lastUsageStr = ''
	local now = getRealTime().timestamp
	if(teamInfo.lastUsage > 0) then
		local days = math.floor(now/(24*3600)) - math.floor(teamInfo.lastUsage/(24*3600))
		if(days == 0) then
			lastUsageStr = "today"
		elseif(days == 1) then
			lastUsageStr = "yesterday"
		else
			lastUsageStr = MuiGetMsg("%u days ago"):format(days)
		end
	end
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.lastUsageCol, lastUsageStr, false, false)
	guiGridListSetItemData(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo)
end

local function updateList(teams, selectedID, selectedCol)
	-- Save scrollbars position
	local scrollH = guiGridListGetHorizontalScrollPosition(g_GUI.teamsList)
	local scrollV = guiGridListGetVerticalScrollPosition(g_GUI.teamsList)
	
	-- Clear list
	guiGridListClear(g_GUI.teamsList)
	
	-- Add all items back
	for i, teamInfo in ipairs(teams) do
		local row = guiGridListAddRow(g_GUI.teamsList)
		updateRow(row, teamInfo)
		if(selectedID == teamInfo.id) then
			guiGridListSetSelectedItem(g_GUI.teamsList, row, selectedCol)
		end
	end
	
	-- Restore scrollbars position
	-- HACKFIX: guiGridListSet*ScrollPosition doesn't work just after guiGridListClear so delay it a bit
	delayExecution(function()
		guiGridListSetHorizontalScrollPosition(g_GUI.teamsList, scrollH)
		guiGridListSetVerticalScrollPosition(g_GUI.teamsList, scrollV)
	end)
end

local function onDelResult(row, success)
	if(success) then
		guiGridListRemoveRow(g_GUI.teamsList, row)
	end
end

local function onDelClick()
	local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
	if(not row or row == -1) then return end
	
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, row, g_GUI.nameCol)
	if(teamInfo.id) then
		RPC('Teams.delItemRPC', teamInfo.id):onResult(onDelResult, row):exec()
	else
		guiGridListRemoveRow(g_GUI.teamsList, row)
	end
end

local function onAddClick()
	local row = guiGridListAddRow(g_GUI.teamsList)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.nameCol, '', false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.typeCol, "Tag", false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.tagCol, '', false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.clrCol, '', false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.lastUsageCol, '', false, false)
	local teamInfo = {name = '', tag = '', aclGroup = '', color = '', lastUsage = 0}
	guiGridListSetItemData(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo, false, false)
end

local function onChgPriResult(teams)
	if(teams) then
		local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
		local teamInfo = row and row > -1 and guiGridListGetItemData(g_GUI.teamsList, row, g_GUI.nameCol)
		updateList(teams, teamInfo and teamInfo.id, col)
	end
end

local function onUpClick()
	local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
	local teamInfo = row and row > -1 and guiGridListGetItemData(g_GUI.teamsList, row, g_GUI.nameCol)
	if(not teamInfo or not teamInfo.id) then return end
	RPC('Teams.changePriority', teamInfo.id, true):onResult(onChgPriResult):exec()
end

local function onDownClick()
	local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
	local teamInfo = row and row > -1 and guiGridListGetItemData(g_GUI.teamsList, row, g_GUI.nameCol)
	if(not teamInfo or not teamInfo.id) then return end
	RPC('Teams.changePriority', teamInfo.id, false):onResult(onChgPriResult):exec()
end

local function onUpdateClick()
	RPC('Teams.updateAllPlayers'):exec()
end

local function onSaveResult(row, teamInfo)
	if(not g_GUI or not teamInfo) then return end
	updateRow(row, teamInfo)
end

local function onEditAccepted()
	local newText = guiGetText(source)
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol)
	
	if(g_GUI.clickedCol == g_GUI.nameCol) then
		teamInfo.name = newText
	elseif(g_GUI.clickedCol == g_GUI.tagCol) then
		if(teamInfo.aclGroup == '') then
			teamInfo.tag = newText
		else
			teamInfo.aclGroup = newText
		end
	elseif(g_GUI.clickedCol == g_GUI.clrCol) then
		local r, g, b = getColorFromString(newText)
		teamInfo.color = r and newText or ''
	end
	
	guiGridListSetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol, teamInfo, false, false)
	RPC('Teams.updateItemRPC', teamInfo):onResult(onSaveResult, g_GUI.clickedRow):exec()
	
	destroyElement(source)
	g_CtxEdit = false
end

local function onTypeClick()
	local row, col = guiGridListGetSelectedItem(source)
	if(not row or row == -1) then return end
	
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol)
	
	local tagOrGroup = teamInfo.tag == '' and teamInfo.aclGroup or teamInfo.tag
	if(row == 0) then -- tag
		teamInfo.tag = tagOrGroup
		teamInfo.aclGroup = ''
	else
		teamInfo.aclGroup = tagOrGroup
		teamInfo.tag = ''
	end
	
	guiGridListSetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol, teamInfo, false, false)
	RPC('Teams.updateItemRPC', teamInfo):onResult(onSaveResult, g_GUI.clickedRow):exec()
	
	destroyElement(source)
	g_CtxEdit = false
end

local function destroyOnBlur()
	destroyElement(source)
	g_CtxEdit = false
end

local function onListDblClick(btn, state, absX, absY)
	-- Use g_CtxEdit variable because sometimes MTA doesn't send onBlur event when opening Menu
	if(g_CtxEdit) then
		destroyElement(g_CtxEdit)
		g_CtxEdit = false
	end
	
	local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
	if(not row or row == -1) then return end
	
	local wndX, wndY = guiGetPosition(g_GUI.wnd, false)
	local x, y = absX - wndX, absY - wndY
	
	g_GUI.clickedRow = row
	g_GUI.clickedCol = col
	
	local text = guiGridListGetItemText(g_GUI.teamsList, row, col)
	if(col == g_GUI.nameCol or col == g_GUI.tagCol or col == g_GUI.clrCol) then
		local edit = guiCreateEdit(absX, absY, 200, 20, text, false)
		guiEditSetCaretIndex(edit, text:len())
		guiBringToFront(edit)
		addEventHandler('onClientGUIAccepted', edit, onEditAccepted, false)
		addEventHandler('onClientGUIBlur', edit, destroyOnBlur, false)
		g_CtxEdit = edit
	else
		local list = guiCreateGridList(absX, absY, 200, 100, false)
		local col = guiGridListAddColumn(list, "Type", 0.9)
		local tagRow = guiGridListAddRow(list)
		guiGridListSetItemText(list, tagRow, col, "Tag", false, false)
		local aclRow = guiGridListAddRow(list)
		guiGridListSetItemText(list, aclRow, col, "ACL", false, false)
		guiGridListSetSelectedItem(list, text == "Tag" and tagRow or aclRow, col)
		guiBringToFront(list)
		addEventHandler('onClientGUIDoubleClick', list, onTypeClick, false)
		addEventHandler('onClientGUIBlur', list, destroyOnBlur, false)
		g_CtxEdit = list
	end
end

function TeamsAdmin:isVisible()
	return g_GUI and true
end

function TeamsAdmin:show()
	if(self:isVisible()) then return end
	
	AdminPath:hide()
	AdminPath = PanelPath(AdminPanel, TeamsAdmin)
	
	g_GUI = GUI.create('teamsAdmin')
	
	g_GUI.pathView = PanelPathView(AdminPath, Vector2(10, 25), g_GUI.wnd)
	
	guiGridListSetSelectionMode(g_GUI.teamsList, 2)
	
	addEventHandler('onClientGUIClick', g_GUI.close, function() TeamsAdmin:hide() end, false)
	addEventHandler('onClientGUIClick', g_GUI.add, onAddClick, false)
	addEventHandler('onClientGUIClick', g_GUI.del, onDelClick, false)
	addEventHandler('onClientGUIClick', g_GUI.up, onUpClick, false)
	addEventHandler('onClientGUIClick', g_GUI.down, onDownClick, false)
	addEventHandler('onClientGUIClick', g_GUI.update, onUpdateClick, false)
	addEventHandler('onClientGUIDoubleClick', g_GUI.teamsList, onListDblClick, false)
	
	showCursor(true)
	
	RPC('Teams.getList'):onResult(updateList):exec()
end

function TeamsAdmin:hide()
	if(not self:isVisible()) then return end
	
	g_GUI:destroy()
	g_GUI = false
	
	if(g_CtxEdit) then
		destroyElement(g_CtxEdit)
		g_CtxEdit = false
	end
	
	showCursor(false)
end
