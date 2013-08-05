local LocaleAdmin = {}
LocaleAdmin.idToLocale = {}
LocaleAdmin.pathName = "Interface Translation"

local LocaleStrList = {}
LocaleStrList.pathName = ''
LocaleStrList.idToRow = {}

AdminPanel:addItem{
	name = "Interface Translation",
	right = AccessRight('mui'),
	exec = function(self)
		LocaleAdmin:show(path)
		return true
	end,
}

function LocaleAdmin:onLocaleList(locales, strCount)
	for i, info in ipairs(locales) do
		local locale = LocaleList.get(info.code)
		local state = info.state
		
		local stateStr = state.count..'/'..strCount
		if(state.missing > 0 or state.unknown > 0) then
			stateStr = stateStr..' '..MuiGetMsg("(missing: %u, unknown: %u)"):format(state.missing, state.unknown)
		end
		
		local row = guiGridListAddRow(self.gui.list)
		guiGridListSetItemText(self.gui.list, row, self.gui.nameCol, locale.name, false, true)
		guiGridListSetItemText(self.gui.list, row, self.gui.stateCol, stateStr, false, true)
		
		if(info.access) then
			guiGridListSetItemData(self.gui.list, row, self.gui.nameCol, locale.code)
		else
			guiGridListSetItemColor(self.gui.list, row, self.gui.nameCol, 128, 128, 128)
			guiGridListSetItemColor(self.gui.list, row, self.gui.stateCol, 128, 128, 128)
		end
	end
end

function LocaleAdmin:isVisible()
	return self.gui and guiGetVisible(self.gui.wnd)
end

function LocaleAdmin:show()
	if(self:isVisible()) then return end
	
	AdminPath:hide()
	AdminPath = PanelPath(AdminPanel, LocaleAdmin)
	
	self.gui = GUI.create('transMain')
	self.pathView = PanelPathView(AdminPath, Vector2(10, 25), self.gui.wnd)
	
	RPC('mui.getLocaleList'):onResult(self.onLocaleList, self):exec()
	
	addEventHandler('onClientGUIClick', self.gui.edit, LocaleAdmin.onEditClick, false)
	addEventHandler('onClientGUIDoubleClick', self.gui.list, LocaleAdmin.onEditClick, false)
	
	showCursor(true)
end

function LocaleAdmin:hide()
	if(not self:isVisible()) then return end
	
	self.gui:destroy()
	self.gui = false
	
	showCursor(false)
end

function LocaleAdmin.onEditClick()
	local self = LocaleAdmin
	local row, col = guiGridListGetSelectedItem(self.gui.list)
	if(row == -1) then return end
	
	local code = guiGridListGetItemData(self.gui.list, row, self.gui.nameCol)
	local locale = LocaleList.get(code)
	LocaleStrList:setLocale(locale)
	LocaleStrList:show()
end

function LocaleStrList:setLocale(locale)
	self.locale = locale
	LocaleStrList.pathName = locale.name
	
	if(self.gui) then
		self:refreshLocale()
	end
end

function LocaleStrList:closeEditWnd()
	self.editGui:destroy()
	self.editGui = false
	showCursor(false)
end

function LocaleStrList:refreshLocale()
	RPC('mui.getLocaleData', self.locale.code):onResult(self.onLocaleData, self):exec()
	
	if(self.editGui) then
		self:closeEditWnd()
	end
end

function LocaleStrList:acceptEditWnd()
	local id = guiGetText(self.editGui.id)
	local val = guiGetText(self.editGui.val)
	local TYPES = {[0] = 's', [1] = 'c', [2] = '*'}
	local typeIdx = guiComboBoxGetSelected(self.editGui.type)
	local strType = TYPES[typeIdx]
	
	local state = self.editGui.state
	local listEl = state and self.gui['msgList_'..state]
	local row = self.editGui.row
	local oldId = false
	if(row) then
		-- Check if it wont overwrite another string
		oldId = guiGridListGetItemText(listEl, row, self.gui['idCol_'..state])
		if(id ~= oldId and self.idToState[id] and self.idToState[id] ~= 'm') then
			outputChatBox("Such string already exists!", 255, 0, 0)
			return
		end
	end
	
	-- Check what is the new state of this string
	local newState = 'u'
	if(self.idToState[id] == 'v' or self.idToState[id] == 'm') then
		newState = 'v'
	end
	
	-- Check if we are overwriting row in another list
	local state2 = self.idToState[id]
	if(state2 and state2 ~= state) then
		local row2 = self.idToRow[id]
		guiGridListRemoveRow(self.gui['msgList_'..state2], row2)
	end
	
	if(state and state ~= newState) then
		-- Remove row from old list
		guiGridListRemoveRow(listEl, row)
		row = false
	end
	
	if(oldId) then
		-- Remove from maps for a moment
		self.idToRow[oldId] = nil
		self.idToState[oldId] = nil
	end
	
	state = newState
	listEl = state and self.gui['msgList_'..state]
	if(not row) then
		-- Add new row if needed
		row = guiGridListAddRow(listEl)
	end
	
	-- Setup cells
	guiGridListSetItemText(listEl, row, self.gui['idCol_'..state], id, false, false)
	guiGridListSetItemText(listEl, row, self.gui['valCol_'..state], val, false, false)
	guiGridListSetItemData(listEl, row, self.gui['idCol_'..state], strType)
	
	-- Add string to maps again
	self.idToRow[id] = row
	self.idToState[id] = state
	
	-- Finally notify the server about all changes
	if(oldId and oldId ~= id) then
		RPC('mui.removeString', self.locale.code, oldId):exec()
	end
	RPC('mui.setString', self.locale.code, id, val, strType):exec()
	
	-- Update tab titles and close window
	self:updateTabTitles()
	self:closeEditWnd()
end

function LocaleStrList:prepareEditWnd(state, row)
	if(not self.editGui) then
		self.editGui = GUI.create('transEdit')
		guiComboBoxAddItem(self.editGui.type, "Server")
		guiComboBoxAddItem(self.editGui.type, "Client")
		guiComboBoxAddItem(self.editGui.type, "Shared")
		
		addEventHandler('onClientGUIClick', self.editGui.ok, function() self:acceptEditWnd() end, false)
		addEventHandler('onClientGUIClick', self.editGui.cancel, function() self:closeEditWnd() end, false)
		
		showCursor(true)
	end
	
	local id, val, strType = '', '', 's'
	
	self.editGui.state = state
	self.editGui.row = row
	if(state) then
		local listEl = self.gui['msgList_'..state]
		id = guiGridListGetItemText(listEl, row, self.gui['idCol_'..state])
		val = guiGridListGetItemText(listEl, row, self.gui['valCol_'..state])
		strType = guiGridListGetItemData(listEl, row, self.gui['idCol_'..state])
	end
	
	guiSetText(self.editGui.id, id)
	guiSetText(self.editGui.val, val)
	local TYPE_TO_IDX = {s = 0, c = 1, ['*'] = 2}
	guiComboBoxSetSelected(self.editGui.type, TYPE_TO_IDX[strType])
end

function LocaleStrList.onEditClick()
	local self = LocaleStrList
	local tab = guiGetSelectedTab(self.gui.tabs)
	local state = self.tabToState[tab]
	local listEl = self.gui['msgList_'..state]
	local row, col = guiGridListGetSelectedItem(listEl)
	if(row == -1) then return end
	
	self:prepareEditWnd(state, row)
end

function LocaleStrList.onAddClick()
	local self = LocaleStrList
	self:prepareEditWnd()
end

function LocaleStrList.onDelClick()
	local self = LocaleStrList
	local tab = guiGetSelectedTab(self.gui.tabs)
	local state = self.tabToState[tab]
	
	if(state == 'm') then return end
	
	local listEl = self.gui['msgList_'..state]
	local row, col = guiGridListGetSelectedItem(listEl)
	if(row == -1) then return end
	
	local id = guiGridListGetItemText(listEl, row, self.gui['idCol_'..state])
	
	guiGridListRemoveRow(listEl, row)
	RPC('mui.removeString', self.locale.code, id):exec()
	self:updateTabTitles()
end

function LocaleStrList:updateTabTitles()
	local TAB_TITLES = {v = "Valid (%u)", m = "Missing (%u)", u = "Unknown (%u)"}
	local STATES = {'v', 'm', 'u'}
	for i, state in ipairs(STATES) do
		local tabEl = self.gui['tab_'..state]
		local listEl = self.gui['msgList_'..state]
		local count = guiGridListGetRowCount(listEl)
		guiSetText(tabEl, MuiGetMsg(TAB_TITLES[state]):format(count))
	end
end

function LocaleStrList:updateList(state, list)
	local listEl = self.gui['msgList_'..state]
	local idCol = self.gui['idCol_'..state]
	local valCol = self.gui['valCol_'..state]
	guiGridListClear(listEl)
	for i, entry in ipairs(list) do
		local row = guiGridListAddRow(listEl)
		guiGridListSetItemText(listEl, row, idCol, entry.id, false, false)
		guiGridListSetItemText(listEl, row, valCol, entry.val or '', false, false)
		guiGridListSetItemData(listEl, row, idCol, entry.t)
		
		self.idToRow[entry.id] = row
		self.idToState[entry.id] = state
	end
end

function LocaleStrList:onLocaleData(locCode, validList, missingList, unknownList)
	if(self.locale.code ~= locCode or not self.gui) then return end
	
	self.idToRow = {}
	self.idToState = {}
	
	local STATES = {'v', 'm', 'u'}
	for i, list in ipairs({validList, missingList, unknownList}) do
		self:updateList(STATES[i], list)
	end
	
	self:updateTabTitles()
end

function LocaleStrList:initGui()
	self.gui = GUI.create('transPanel')
	
	self.pathView = PanelPathView(AdminPath, Vector2(10, 25), self.gui.wnd)
	
	addEventHandler('onClientGUIClick', self.gui.close, function() self:hide() end, false)
	addEventHandler('onClientGUIClick', self.gui.add, LocaleStrList.onAddClick, false)
	addEventHandler('onClientGUIClick', self.gui.edit, LocaleStrList.onEditClick, false)
	addEventHandler('onClientGUIClick', self.gui.del, LocaleStrList.onDelClick, false)
	addEventHandler('onClientGUIDoubleClick', self.gui.msgList_v, LocaleStrList.onEditClick, false)
	addEventHandler('onClientGUIDoubleClick', self.gui.msgList_m, LocaleStrList.onEditClick, false)
	addEventHandler('onClientGUIDoubleClick', self.gui.msgList_u, LocaleStrList.onEditClick, false)
	
	MuiIgnoreElement(self.gui.msgList_v)
	MuiIgnoreElement(self.gui.msgList_m)
	MuiIgnoreElement(self.gui.msgList_u)
	
	self.tabToState = {[self.gui.tab_v] = 'v', [self.gui.tab_m] = 'm', [self.gui.tab_u] = 'u'}
	
	self:refreshLocale()
end

function LocaleStrList:show()
	if(self:isVisible()) then return end
	
	AdminPath:hide()
	AdminPath = PanelPath(AdminPanel, LocaleAdmin, LocaleStrList)
	
	if(not self.gui) then
		self:initGui()
	end
	
	showCursor(true)
end

function LocaleStrList:hide()
	if(not self:isVisible()) then return end
	
	self.gui:destroy()
	self.gui = false
	
	showCursor(false)
end

function LocaleStrList:isVisible()
	return self.gui and true
end
