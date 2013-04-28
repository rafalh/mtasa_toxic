local g_GUI = false

local function closeTeamsAdmin()
	g_GUI:destroy()
	g_GUI = false
	guiSetInputEnabled(false)
end

local function onDelClick()
	local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
	if(not row or row == -1) then return end
	
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, row, g_GUI.nameCol)
	guiGridListRemoveRow(g_GUI.teamsList, row)
	if(teamInfo) then
		RPC("deleteTeamInfo", teamInfo):exec()
	end
end

local function onAddClick()
	local row = guiGridListAddRow(g_GUI.teamsList)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.nameCol, "", false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.typeCol, "Tag", false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.tagCol, "", false, false)
	guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.clrCol, "", false, false)
end

local function onEditAccepted()
	local newText = guiGetText(source)
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol)
	local oldTeamInfo = teamInfo and table.copy(teamInfo)
	
	if(not teamInfo) then
		teamInfo = {name = "", clan = ""}
	end
	
	guiGridListSetItemText(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.clickedCol, newText, false, false)
	if(g_GUI.clickedCol == g_GUI.nameCol) then
		teamInfo.name = newText
	elseif(g_GUI.clickedCol == g_GUI.tagCol) then
		if(teamInfo.clan) then
			teamInfo.clan = newText
		else
			teamInfo.acl_group = newText
		end
	elseif(g_GUI.clickedCol == g_GUI.clrCol) then
		local r, g, b = getColorFromString(newText)
		teamInfo.color = r and newText
		if(r) then
			guiGridListSetItemColor(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.clrCol, r, g, b)
		end
	end
	guiGridListSetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol, teamInfo, false, false)
	RPC("saveTeamInfo", teamInfo, oldTeamInfo):exec()
	destroyElement(source)
end

local function onEditBlur()
	destroyElement(source)
end

local function onListDblClick(btn, state, absX, absY)
	local row, col = guiGridListGetSelectedItem(g_GUI.teamsList)
	if(not row or row == -1) then return end
	
	local wndX, wndY = guiGetPosition(g_GUI.wnd, false)
	local x, y = absX - wndX, absY - wndY
	
	g_GUI.clickedRow = row
	g_GUI.clickedCol = col
	local text = guiGridListGetItemText(g_GUI.teamsList, row, col)
	local edit = guiCreateEdit(x, y, 200, 20, text, false, g_GUI.wnd)
	guiEditSetCaretIndex(edit, text:len())
	guiBringToFront(edit)
	addEventHandler("onClientGUIAccepted", edit, onEditAccepted, false)
	addEventHandler("onClientGUIBlur", edit, onEditBlur, false)
end

function openTeamsAdmin(teams)
	if(g_GUI) then return end
	
	g_GUI = GUI.create("teamsAdmin")
	
	guiGridListSetSelectionMode(g_GUI.teamsList, 2)
	
	addEventHandler("onClientGUIClick", g_GUI.close, closeTeamsAdmin, false)
	addEventHandler("onClientGUIClick", g_GUI.add, onAddClick, false)
	addEventHandler("onClientGUIClick", g_GUI.del, onDelClick, false)
	addEventHandler("onClientGUIDoubleClick", g_GUI.teamsList, onListDblClick, false)
	
	guiSetInputEnabled(true)
	
	for i, teamInfo in ipairs(teams) do
		local row = guiGridListAddRow(g_GUI.teamsList)
		local tag = teamInfo.clan or teamInfo.acl_group
		guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo.name or tag, false, false)
		guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.typeCol, teamInfo.clan and "Tag" or "ACL", false, false)
		guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.tagCol, tag, false, false)
		if(teamInfo.color) then
			guiGridListSetItemText(g_GUI.teamsList, row, g_GUI.clrCol, teamInfo.color, false, false)
			local r, g, b = getColorFromString(teamInfo.color)
			if(r) then
				guiGridListSetItemColor(g_GUI.teamsList, row, g_GUI.clrCol, r, g, b)
			end
		end
		guiGridListSetItemData(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo)
	end
end
