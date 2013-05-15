local g_GUI, g_EditGui
local g_LocaleCode
local g_IdToLocale = {}

addEvent("main.openTransPanel", true)
addEvent("main.onLocaleData", true)

local function closePanel()
	g_GUI:destroy()
	g_GUI = false
	showCursor(false)
end

local function closeEditWnd()
	g_EditGui:destroy()
	g_EditGui = false
	showCursor(false)
end

local function refreshLocale()
	local id = guiComboBoxGetSelected(g_GUI.langs)
	local locale = g_IdToLocale[id]
	g_LocaleCode = locale.code
	triggerServerEvent("main.onLocaleDataReq", g_ResRoot, g_LocaleCode)
	
	if(g_EditGui) then
		closeEditWnd()
	end
end

local function acceptEditWnd()
	local row = g_EditGui.row
	local info, oldId = {}, false
	
	if(not row) then
		info[1] = guiCheckBoxGetSelected(g_EditGui.pattern)
		info[2] = guiCheckBoxGetSelected(g_EditGui.client)
		
		row = guiGridListAddRow(g_GUI.msgList)
	else
		info = guiGridListGetItemData(g_GUI.msgList, row, g_GUI.idCol)
		oldId = guiGridListGetItemText(g_GUI.msgList, row, g_GUI.idCol)
	end
	
	local entry = {}
	entry.id = guiGetText(g_EditGui.id)
	entry.val = guiGetText(g_EditGui.val)
	entry.pattern = info[1]
	
	guiGridListSetItemText(g_GUI.msgList, row, g_GUI.idCol, entry.id, false, false)
	guiGridListSetItemText(g_GUI.msgList, row, g_GUI.valCol, entry.val, false, false)
	guiGridListSetItemData(g_GUI.msgList, row, g_GUI.idCol, info)
	
	triggerServerEvent("main.onChangeLocaleReq", g_ResRoot, g_LocaleCode, entry, oldId, info[2])
	
	closeEditWnd()
end

local function prepareEditWnd(row)
	if(not g_EditGui) then
		g_EditGui = GUI.create("transEdit")
		showCursor(true)
		addEventHandler("onClientGUIClick", g_EditGui.ok, acceptEditWnd, false)
		addEventHandler("onClientGUIClick", g_EditGui.cancel, closeEditWnd, false)
	end
	
	local id, val = "", ""
	local info = {false, false}
	
	g_EditGui.row = row
	if(row) then
		id = guiGridListGetItemText(g_GUI.msgList, row, g_GUI.idCol)
		val = guiGridListGetItemText(g_GUI.msgList, row, g_GUI.valCol)
		info = guiGridListGetItemData(g_GUI.msgList, row, g_GUI.idCol)
	end
	
	guiSetText(g_EditGui.id, id)
	guiSetText(g_EditGui.val, val)
	guiCheckBoxSetSelected(g_EditGui.pattern, info[1])
	guiCheckBoxSetSelected(g_EditGui.client, info[2])
end

local function onEditClick()
	local row, col = guiGridListGetSelectedItem(g_GUI.msgList)
	if(row == -1) then return end
	
	prepareEditWnd(row)
end

local function onAddClick()
	if(not g_LocaleCode) then return end
	prepareEditWnd()
end

local function onDelClick()
	local row, col = guiGridListGetSelectedItem(g_GUI.msgList)
	if(row == -1) then return end
	
	local id = guiGridListGetItemText(g_GUI.msgList, row, g_GUI.idCol)
	local info = guiGridListGetItemData(g_GUI.msgList, row, g_GUI.idCol)
	assert(info)
	guiGridListRemoveRow(g_GUI.msgList, row)
	triggerServerEvent("main.onChangeLocaleReq", g_ResRoot, g_LocaleCode, false, id, info[2])
end

local function onLocaleData(locCode, tblS, tblC)
	if(g_LocaleCode ~= locCode or not g_GUI) then return end
	
	guiGridListClear(g_GUI.msgList)
	
	local row = guiGridListAddRow(g_GUI.msgList)
	guiGridListSetItemText(g_GUI.msgList, row, g_GUI.idCol, "Server", true, false)
	
	for i, entry in ipairs(tblS) do
		local row = guiGridListAddRow(g_GUI.msgList)
		guiGridListSetItemText(g_GUI.msgList, row, g_GUI.idCol, entry.id, false, false)
		guiGridListSetItemText(g_GUI.msgList, row, g_GUI.valCol, entry.val, false, false)
		guiGridListSetItemData(g_GUI.msgList, row, g_GUI.idCol, {entry.pattern or false, false})
	end
	
	local row = guiGridListAddRow(g_GUI.msgList)
	guiGridListSetItemText(g_GUI.msgList, row, g_GUI.idCol, "Client", true, false)
	
	for i, entry in ipairs(tblC) do
		local row = guiGridListAddRow(g_GUI.msgList)
		guiGridListSetItemText(g_GUI.msgList, row, g_GUI.idCol, entry.id, false, false)
		guiGridListSetItemText(g_GUI.msgList, row, g_GUI.valCol, entry.val, false, false)
		guiGridListSetItemData(g_GUI.msgList, row, g_GUI.idCol, {entry.pattern or false, true})
	end
end

local function initGui(langCodes)
	g_GUI = GUI.create("transPanel")
	
	for i, code in ipairs(langCodes) do
		local locale = LocaleList.get(code)
		local id = guiComboBoxAddItem(g_GUI.langs, locale.name)
		g_IdToLocale[id] = locale
	end
	guiComboBoxSetSelected(g_GUI.langs, 0)
	refreshLocale()
	addEventHandler("onClientGUIComboBoxAccepted", g_GUI.langs, refreshLocale, false)
	
	
	addEventHandler("onClientGUIClick", g_GUI.close, closePanel, false)
	addEventHandler("onClientGUIClick", g_GUI.add, onAddClick, false)
	addEventHandler("onClientGUIClick", g_GUI.edit, onEditClick, false)
	addEventHandler("onClientGUIClick", g_GUI.del, onDelClick, false)
	addEventHandler("onClientGUIDoubleClick", g_GUI.msgList, onEditClick, false)
	
	MuiIgnoreElement(g_GUI.msgList)
end

local function openPanel(langCodes)
	if(not g_GUI) then
		initGui(langCodes)
		
		showCursor(true)
	end
end

local function transPanelCmd()
	triggerServerEvent("main.onTransPanelReq", g_ResRoot)
end

addCommandHandler("transpanel", transPanelCmd, false)
addEventHandler("main.openTransPanel", g_ResRoot, openPanel)
addEventHandler("main.onLocaleData", g_ResRoot, onLocaleData)
