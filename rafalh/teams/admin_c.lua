local g_GUI = false
local g_Teams = {}

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
	local teamInfo = {name = "", tag = "", aclGroup = "", color = ""}
	guiGridListSetItemData(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo, false, false)
end

local function onUpClick()
	
end

local function onDownClick()
	
end

local function onEditAccepted()
	local newText = guiGetText(source)
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol)
	
	guiGridListSetItemText(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.clickedCol, newText, false, false)
	if(g_GUI.clickedCol == g_GUI.nameCol) then
		teamInfo.name = newText
	elseif(g_GUI.clickedCol == g_GUI.tagCol) then
		if(teamInfo.aclGroup == "") then
			teamInfo.tag = newText
		else
			teamInfo.aclGroup = newText
		end
	elseif(g_GUI.clickedCol == g_GUI.clrCol) then
		local r, g, b = getColorFromString(newText)
		teamInfo.color = r and newText
		if(r) then
			guiGridListSetItemColor(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.clrCol, r, g, b)
		end
	end
	guiGridListSetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol, teamInfo, false, false)
	RPC("saveTeamInfo", teamInfo):exec()
	destroyElement(source)
end

local function onTypeClick()
	local row, col = guiGridListGetSelectedItem(source)
	if(not row or row == -1) then return end
	
	local teamInfo = guiGridListGetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol)
	
	local tagOrGroup = teamInfo.tag == "" and teamInfo.aclGroup or teamInfo.tag
	if(row == 0) then -- tag
		teamInfo.tag = tagOrGroup
		teamInfo.aclGroup = ""
	else
		teamInfo.aclGroup = tagOrGroup
		teamInfo.tag = ""
	end
	
	local typeStr = teamInfo.tag ~= "" and "Tag" or "ACL"
	guiGridListSetItemData(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.nameCol, teamInfo, false, false)
	guiGridListSetItemText(g_GUI.teamsList, g_GUI.clickedRow, g_GUI.typeCol, typeStr, false, false)
	RPC("saveTeamInfo", teamInfo):exec()
	destroyElement(source)
end

local function destroyOnBlur()
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
	if(col == g_GUI.nameCol or col == g_GUI.tagCol or col == g_GUI.clrCol) then
		local edit = guiCreateEdit(absX, absY, 200, 20, text, false)
		guiEditSetCaretIndex(edit, text:len())
		guiBringToFront(edit)
		addEventHandler("onClientGUIAccepted", edit, onEditAccepted, false)
		addEventHandler("onClientGUIBlur", edit, destroyOnBlur, false)
	else
		local list = guiCreateGridList(absX, absY, 200, 100, false)
		local col = guiGridListAddColumn(list, "Type", 0.9)
		local tagRow = guiGridListAddRow(list)
		guiGridListSetItemText(list, tagRow, col, "Tag", false, false)
		local aclRow = guiGridListAddRow(list)
		guiGridListSetItemText(list, aclRow, col, "ACL", false, false)
		guiGridListSetSelectedItem(list, text == "Tag" and tagRow or aclRow, col)
		guiBringToFront(list)
		addEventHandler("onClientGUIDoubleClick", list, onTypeClick, false)
		addEventHandler("onClientGUIBlur", list, destroyOnBlur, false)
	end
end

function openTeamsAdmin(teams)
	if(g_GUI) then return end
	
	g_GUI = GUI.create("teamsAdmin")
	g_Teams = teams
	
	guiGridListSetSelectionMode(g_GUI.teamsList, 2)
	
	addEventHandler("onClientGUIClick", g_GUI.close, closeTeamsAdmin, false)
	addEventHandler("onClientGUIClick", g_GUI.add, onAddClick, false)
	addEventHandler("onClientGUIClick", g_GUI.del, onDelClick, false)
	addEventHandler("onClientGUIClick", g_GUI.up, onUpClick, false)
	addEventHandler("onClientGUIClick", g_GUI.down, onDownClick, false)
	addEventHandler("onClientGUIDoubleClick", g_GUI.teamsList, onListDblClick, false)
	
	guiSetInputEnabled(true)
	
	for i, teamInfo in ipairs(teams) do
		local row = guiGridListAddRow(g_GUI.teamsList)
		local tagOrGroup = teamInfo.tag == "" and teamInfo.aclGroup or teamInfo.tag
		local typeStr = teamInfo.tag ~= "" and "Tag" or "ACL"
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
		guiGridListSetItemData(g_GUI.teamsList, row, g_GUI.nameCol, teamInfo)
	end
end
