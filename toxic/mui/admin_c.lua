local LocaleAdmin = {}
LocaleAdmin.idToLocale = {}
LocaleAdmin.pathName = "Interface Translation"

AdminPanel:addItem{
	name = "Interface Translation",
	right = AccessRight('mui'),
	exec = function(self)
		LocaleAdmin:show(path)
		return true
	end,
}

addEvent('main.onLocaleData', true)

function LocaleAdmin:closeEditWnd()
	self.editGui:destroy()
	self.editGui = false
	showCursor(false)
end

function LocaleAdmin:refreshLocale()
	local id = guiComboBoxGetSelected(self.gui.langs)
	local locale = self.idToLocale[id]
	self.localeCode = locale.code
	triggerServerEvent('main.onLocaleDataReq', g_ResRoot, self.localeCode)
	
	if(self.editGui) then
		self:closeEditWnd()
	end
end

function LocaleAdmin:acceptEditWnd()
	local row = self.editGui.row
	local info, oldId = {}, false
	
	if(not row) then
		info[1] = guiCheckBoxGetSelected(self.editGui.pattern)
		info[2] = guiCheckBoxGetSelected(self.editGui.client)
		
		row = guiGridListAddRow(self.gui.msgList)
	else
		info = guiGridListGetItemData(self.gui.msgList, row, self.gui.idCol)
		oldId = guiGridListGetItemText(self.gui.msgList, row, self.gui.idCol)
	end
	
	local entry = {}
	entry.id = guiGetText(self.editGui.id)
	entry.val = guiGetText(self.editGui.val)
	entry.pattern = info[1]
	
	guiGridListSetItemText(self.gui.msgList, row, self.gui.idCol, entry.id, false, false)
	guiGridListSetItemText(self.gui.msgList, row, self.gui.valCol, entry.val, false, false)
	guiGridListSetItemData(self.gui.msgList, row, self.gui.idCol, info)
	
	triggerServerEvent('main.onChangeLocaleReq', g_ResRoot, self.localeCode, entry, oldId, info[2])
	
	self:closeEditWnd()
end

function LocaleAdmin:prepareEditWnd(row)
	if(not self.editGui) then
		self.editGui = GUI.create('transEdit')
		showCursor(true)
		addEventHandler('onClientGUIClick', self.editGui.ok, function() self:acceptEditWnd() end, false)
		addEventHandler('onClientGUIClick', self.editGui.cancel, function() self:closeEditWnd() end, false)
	end
	
	local id, val = '', ''
	local info = {false, false}
	
	self.editGui.row = row
	if(row) then
		id = guiGridListGetItemText(self.gui.msgList, row, self.gui.idCol)
		val = guiGridListGetItemText(self.gui.msgList, row, self.gui.valCol)
		info = guiGridListGetItemData(self.gui.msgList, row, self.gui.idCol)
	end
	
	guiSetText(self.editGui.id, id)
	guiSetText(self.editGui.val, val)
	guiCheckBoxSetSelected(self.editGui.pattern, info[1])
	guiCheckBoxSetSelected(self.editGui.client, info[2])
end

function LocaleAdmin.onEditClick()
	local self = LocaleAdmin
	local row, col = guiGridListGetSelectedItem(self.gui.msgList)
	if(row == -1) then return end
	
	self:prepareEditWnd(row)
end

function LocaleAdmin.onAddClick()
	local self = LocaleAdmin
	if(not self.localeCode) then return end
	self:prepareEditWnd()
end

function LocaleAdmin.onDelClick()
	local row, col = guiGridListGetSelectedItem(self.gui.msgList)
	if(row == -1) then return end
	
	local id = guiGridListGetItemText(self.gui.msgList, row, self.gui.idCol)
	local info = guiGridListGetItemData(self.gui.msgList, row, self.gui.idCol)
	assert(info)
	guiGridListRemoveRow(self.gui.msgList, row)
	triggerServerEvent('main.onChangeLocaleReq', g_ResRoot, self.localeCode, false, id, info[2])
end

function LocaleAdmin.onLocaleData(locCode, tblS, tblC)
	local self = LocaleAdmin
	if(self.localeCode ~= locCode or not self.gui) then return end
	
	guiGridListClear(self.gui.msgList)
	
	local row = guiGridListAddRow(self.gui.msgList)
	guiGridListSetItemText(self.gui.msgList, row, self.gui.idCol, "Server", true, false)
	
	for i, entry in ipairs(tblS) do
		local row = guiGridListAddRow(self.gui.msgList)
		guiGridListSetItemText(self.gui.msgList, row, self.gui.idCol, entry.id, false, false)
		guiGridListSetItemText(self.gui.msgList, row, self.gui.valCol, entry.val, false, false)
		guiGridListSetItemData(self.gui.msgList, row, self.gui.idCol, {entry.pattern or false, false})
	end
	
	local row = guiGridListAddRow(self.gui.msgList)
	guiGridListSetItemText(self.gui.msgList, row, self.gui.idCol, "Client", true, false)
	
	for i, entry in ipairs(tblC) do
		local row = guiGridListAddRow(self.gui.msgList)
		guiGridListSetItemText(self.gui.msgList, row, self.gui.idCol, entry.id, false, false)
		guiGridListSetItemText(self.gui.msgList, row, self.gui.valCol, entry.val, false, false)
		guiGridListSetItemData(self.gui.msgList, row, self.gui.idCol, {entry.pattern or false, true})
	end
end

function LocaleAdmin:initGui()
	self.gui = GUI.create('transPanel')
	
	RPC('mui.getLangCodes'):onResult(function(langCodes)
		for i, code in ipairs(langCodes) do
			local locale = LocaleList.get(code)
			local id = guiComboBoxAddItem(self.gui.langs, locale.name)
			self.idToLocale[id] = locale
		end
		
		guiComboBoxSetSelected(self.gui.langs, 0)
		self:refreshLocale()
		addEventHandler('onClientGUIComboBoxAccepted', self.gui.langs, function() self:refreshLocale() end, false)
	end):exec()
	
	self.pathView = PanelPathView(AdminPath, Vector2(10, 25), self.gui.wnd)
	
	addEventHandler('onClientGUIClick', self.gui.close, function() self:hide() end, false)
	addEventHandler('onClientGUIClick', self.gui.add, LocaleAdmin.onAddClick, false)
	addEventHandler('onClientGUIClick', self.gui.edit, LocaleAdmin.onEditClick, false)
	addEventHandler('onClientGUIClick', self.gui.del, LocaleAdmin.onDelClick, false)
	addEventHandler('onClientGUIDoubleClick', self.gui.msgList, LocaleAdmin.onEditClick, false)
	
	MuiIgnoreElement(self.gui.msgList)
end

function LocaleAdmin:show()
	if(self:isVisible()) then return end
	
	AdminPath:hide()
	AdminPath = PanelPath(AdminPanel, LocaleAdmin)
	
	if(not self.gui) then
		self:initGui()
	end
	
	showCursor(true)
end

function LocaleAdmin:hide()
	if(not self:isVisible()) then return end
	
	self.gui:destroy()
	self.gui = false
	showCursor(false)
end

function LocaleAdmin:isVisible()
	return self.gui and true
end

addEventHandler('main.onLocaleData', g_ResRoot, LocaleAdmin.onLocaleData)
