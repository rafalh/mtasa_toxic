local LocaleAdmin = {}
LocaleAdmin.idToLocale = {}
LocaleAdmin.pathName = "Interface Translation"

local LocaleStrList = {}
LocaleStrList.pathName = ''

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
			stateStr = stateStr..' '..MuiGetMsg("(missing: %u, unknown: %u, wrong type: %u)"):format(state.missing, state.unknown, state.wrongType)
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

function LocaleStrList:removeStr(id, row)
	local e = self.entryMap[id]
	local state = self.stateMap[id]
	if(not e) then return false end
	
	table.removeValue(self.lists[state], e)
	self.entryMap[id] = nil
	self.stateMap[id] = nil
	
	if(row) then
		local listEl = self.gui['msgList_'..state]
		guiGridListRemoveRow(listEl, row)
		self:updateTab(state)
	else
		self:updateList(state)
	end
	
	return e
end

function LocaleStrList:updateRow(row, e, state)
	local listEl = self.gui['msgList_'..state]
	local idCol = self.gui['idCol_'..state]
	local valCol = self.gui['valCol_'..state]
	local TYPE_NAME = {s = "Server", c = "Client", ['*'] = "Shared"}
	
	guiGridListSetItemText(listEl, row, idCol, e.id, false, false)
	if(state == 't') then
		local comment = MuiGetMsg("Should be: %s"):format(MuiGetMsg(TYPE_NAME[e.vt]))
		guiGridListSetItemText(listEl, row, valCol, comment, false, false)
	elseif(e.val) then
		guiGridListSetItemText(listEl, row, valCol, e.val, false, false)
	end
end

function LocaleStrList:insertStr(e, state)
	-- Add to internal structures
	self.entryMap[e.id] = e
	self.stateMap[e.id] = state
	table.insert(self.lists[state], e)
	
	-- Add to GUI
	local listEl = self.gui['msgList_'..state]
	row = guiGridListAddRow(listEl)
	
	self:updateRow(row, e, state)
	self:updateTab(state)
end

function LocaleStrList:updateStr(e, state, oldID, row)
	if(oldID and oldID ~= e.id) then
		self.entryMap[oldID] = nil
		self.stateMap[oldID] = nil
		self.entryMap[e.id] = e
		self.stateMap[e.id] = state
	end
	
	if(not row) then
		self:updateList(state)
	else
		self:updateRow(row, e, state)
	end
end

function LocaleStrList:acceptEditWnd()
	-- Read data from GUI
	local id = guiGetText(self.editGui.id)
	local val = guiGetText(self.editGui.val)
	local TYPES = {[0] = 's', [1] = 'c', [2] = '*'}
	local typeIdx = guiComboBoxGetSelected(self.editGui.type)
	local typeCh = TYPES[typeIdx]
	
	-- Setup entry reference
	local state = self.editGui.state
	local row = self.editGui.row
	local listEl = state and self.gui['msgList_'..state]
	local oldID
	
	if(row) then
		-- Retrieve old entry
		oldID = guiGridListGetItemText(listEl, row, self.gui['idCol_'..state])
	end
	
	if(oldID and id ~= oldID and state ~= 'u') then
		-- It was a known string but ID has changed - treat it like an insertion
		state, row, oldID = false, false, false
	end
	
	local owEntry, owState
	if(oldID ~= id) then
		-- ID has changed or this is a new string
		owEntry = self.entryMap[id]
		owState = self.stateMap[id]
	end
	
	if(owState == 'm') then
		-- Overwrite missing string
		if(oldID) then
			-- Remove old unknown entry (forget about it)
			assert(state == 'u')
			self:removeStr(oldID, row)
		end
		
		-- Remove missing entry (will be overwritten)
		local e = self:removeStr(id)
		if(typeCh == e.t) then
			state = 'v'
		else
			e.vt = e.t
			state = 't'
		end
		
		e.id = id
		e.val = val
		e.t = typeCh
		self:insertStr(e, state)
	elseif(owState) then
		-- Disallow overwriting known strings
		outputChatBox("Such string already exists!", 255, 0, 0)
		return
	elseif(oldID) then
		-- Just modify entry
		local e = self.entryMap[oldID]
		
		local newState = state
		if(state == 't' and typeCh == e.vt) then
			newState = 'v'
			e.vt = nil
		elseif(state == 'm' or state == 'v') then
			if(typeCh == e.t) then
				newState = 'v'
			else
				e.vt = e.t
				newState = 't'
			end
		end
		
		e.id = id
		e.val = val
		e.t = typeCh
		
		assert(id == oldID or state == 'u')
		if(state == newState) then
			self:updateStr(e, state, oldID, row)
		else
			self:removeStr(oldID, row)
			self:insertStr(e, newState)
		end
	else
		-- New unknown entry
		state = 'u'
		local e = {id = id, val = val, t = typeCh}
		self:insertStr(e, state)
	end
	
	-- Finally notify the server about all changes
	if(oldID and id ~= oldID) then
		RPC('mui.removeString', self.locale.code, oldID):exec()
	end
	RPC('mui.setString', self.locale.code, id, val, typeCh):exec()
	
	-- Close window
	self:closeEditWnd()
end

function LocaleStrList:prepareEditWnd(state, row)
	-- Create Edit GUI if needed
	if(not self.editGui) then
		self.editGui = GUI.create('transEdit')
		guiComboBoxAddItem(self.editGui.type, "Server")
		guiComboBoxAddItem(self.editGui.type, "Client")
		guiComboBoxAddItem(self.editGui.type, "Shared")
		
		addEventHandler('onClientGUIClick', self.editGui.ok, function() self:acceptEditWnd() end, false)
		addEventHandler('onClientGUIClick', self.editGui.cancel, function() self:closeEditWnd() end, false)
	end
	
	-- Allow changing ID only if we add new row or if string is in unknown list
	guiEditSetReadOnly(self.editGui.id, row and state ~= 'u')
	
	-- Save edited row ID
	self.editGui.state = state
	self.editGui.row = row
	
	-- Get entry info
	local e
	if(state) then
		-- Edit existing string
		local listEl = self.gui['msgList_'..state]
		local id = guiGridListGetItemText(listEl, row, self.gui['idCol_'..state])
		e = self.entryMap[id]
	else
		-- New string
		e = {id = '', val = '', t = 's'}
	end
	
	-- Update GUI elements
	guiSetText(self.editGui.id, e.id)
	guiSetText(self.editGui.val, e.val or '')
	local TYPE_TO_IDX = {s = 0, c = 1, ['*'] = 2}
	guiComboBoxSetSelected(self.editGui.type, TYPE_TO_IDX[e.t])
	
	-- Show the cursor when window is ready
	showCursor(true)
	if(row) then
		guiBringToFront(self.editGui.val)
	else
		guiBringToFront(self.editGui.id)
	end
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
	
	-- Get item data
	local id = guiGridListGetItemText(listEl, row, self.gui['idCol_'..state])
	local e = self:removeStr(id, row)
	
	if(state == 'v' or state == 't') then
		-- Add to missing list
		state = 'm'
		if(e.vt) then
			e.t = e.vt
			e.vt = nil
		end
		
		self:insertStr(e, state)
	end
	
	-- Notify server
	RPC('mui.removeString', self.locale.code, id):exec()
end

function LocaleStrList:updateTab(state)
	-- Update tab title
	local TAB_TITLES = {v = "Valid (%u)", m = "Missing (%u)", u = "Unknown (%u)", t = "Wrong type (%u)"}
	local tabEl = self.gui['tab_'..state]
	local list = self.lists[state]
	guiSetText(tabEl, MuiGetMsg(TAB_TITLES[state]):format(#list))
	guiSetVisible(tabEl, #list > 0)
end

function LocaleStrList:updateList(state)
	local list = self.lists[state]
	local listEl = self.gui['msgList_'..state]
	
	-- Clear the list first
	guiGridListClear(listEl)
	
	-- Add all rows
	for i, e in ipairs(list) do
		local row = guiGridListAddRow(listEl)
		self:updateRow(row, e, state)
	end
	
	self:updateTab(state)
end

function LocaleStrList:onLocaleData(locCode, validList, missingList, wrongTypeList, unknownList)
	if(self.locale.code ~= locCode or not self.gui) then return end
	
	self.lists = {}
	self.lists.v = validList
	self.lists.m = missingList
	self.lists.t = wrongTypeList
	self.lists.u = unknownList
	
	self.entryMap = {}
	self.stateMap = {}
	
	local STATES = {'v', 'm', 'u', 't'}
	for i, state in ipairs(STATES) do
		for i, e in ipairs(self.lists[state]) do
			self.stateMap[e.id] = state
			self.entryMap[e.id] = e
		end
		
		self:updateList(state)
	end
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
	addEventHandler('onClientGUIDoubleClick', self.gui.msgList_t, LocaleStrList.onEditClick, false)
	
	MuiIgnoreElement(self.gui.msgList_v)
	MuiIgnoreElement(self.gui.msgList_m)
	MuiIgnoreElement(self.gui.msgList_u)
	MuiIgnoreElement(self.gui.msgList_t)
	
	self.tabToState = {[self.gui.tab_v] = 'v', [self.gui.tab_m] = 'm', [self.gui.tab_u] = 'u', [self.gui.tab_t] = 't'}
	
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
