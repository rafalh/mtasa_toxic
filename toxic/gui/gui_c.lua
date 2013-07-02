GUI = {}
GUI.__mt = {__index = {}}
GUI.templates = false
GUI.wndToObj = {}

local g_ScrSize = Vector2(guiGetScreenSize())

function GUI.loadNode(node)
	local ctrl = xmlNodeGetAttributes(node)
	ctrl.type = xmlNodeGetName(node)
	
	-- Prepare rect
	local absRect = Rect(Vector2(ctrl.x or 0, ctrl.y or 0), Vector2(ctrl.w or 0, ctrl.h or 0))
	local relRect = Rect(Vector2(ctrl.rx or 0, ctrl.ry or 0), Vector2(ctrl.rw or 0, ctrl.rh or 0))
	ctrl.rc = RelRect(absRect, relRect)
	
	-- Unset position members
	ctrl.x, ctrl.y, ctrl.w, ctrl.h = nil, nil, nil, nil
	ctrl.rx, ctrl.ry, ctrl.rw, ctrl.rh = nil, nil, nil, nil
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local child = GUI.loadNode(subnode)
		table.insert(ctrl, child)
	end
	
	return ctrl
end

function GUI.loadTemplates(path)
	local node = xmlLoadFile(path)
	if(not node) then
		outputDebugString("xmlLoadFile "..path.." failed", 2)
		return false
	end
	
	GUI.templates = {}
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local ctrl = GUI.loadNode(subnode)
		if(ctrl.id) then
			GUI.templates[ctrl.id] = ctrl
		end
	end
	
	xmlUnloadFile(node)
	return true
end

function GUI.getTemplate(tplID)
	if(not GUI.templates) then
		if(not GUI.loadTemplates("gui/gui.xml")) then
			outputDebugString("Failed to load GUI", 1)
			return false
		end
	end
	
	local tpl = GUI.templates[tplID]
	return tpl
end

function GUI.computeCtrlPlacement(tpl, parent)
	local parentSize
	if(parent) then
		parentSize = Vector2(guiGetSize(parent, false))
	else
		parentSize = g_ScrSize
	end
	
	return tpl.rc:resolve(parentSize)
end

function GUI.__mt.__index:createControl(tpl, parent)
	local rc = GUI.computeCtrlPlacement(tpl, parent)
	local x, y, w, h = rc[1][1], rc[1][2], rc[2][1], rc[2][2]
	
	local ctrl
	if(tpl.type == "window") then
		ctrl = guiCreateWindow(x, y, w, h, tpl.title or "", false)
		if(tpl.sizeable == "false") then
			guiWindowSetSizable(ctrl, false)
		end
	elseif(tpl.type == "button") then
		ctrl = guiCreateButton(x, y, w, h, tpl.text or "", false, parent)
	elseif(tpl.type == "checkbox") then
		ctrl = guiCreateCheckBox(x, y, w, h, tpl.text or "", tpl.selected == "true", false, parent)
	elseif(tpl.type == "edit") then
		ctrl = guiCreateEdit(x, y, w, h, tpl.text or "", false, parent)
		if (tpl.readonly == "true") then
			guiEditSetReadOnly(ctrl, true)
		end
		if(tonumber(tpl.maxlen)) then
			guiEditSetMaxLength(ctrl, tonumber(tpl.maxlen))
		end
		if(tpl.masked == "true") then
			guiEditSetMasked(ctrl, true)
		end
	elseif(tpl.type == "memo") then
		ctrl = guiCreateMemo(x, y, w, h, tpl.text or "", false, parent)
		if(tpl.readonly == "true") then
			guiMemoSetReadOnly(ctrl, true)
		end
	elseif(tpl.type == "label") then
		ctrl = guiCreateLabel(x, y, w, h, tpl.text or "", false, parent)
		if(tpl.align) then
			guiLabelSetHorizontalAlign(ctrl, tpl.align)
		end
		if(tpl.color) then
			local r, g, b = getColorFromString(tpl.color)
			guiLabelSetColor(ctrl, r or 255, g or 255, b or 255)
		end
	elseif(tpl.type == "image") then
		ctrl = guiCreateStaticImage(x, y, w, h, tpl.src or "", false, parent)
	elseif(tpl.type == "combobox") then
		ctrl = guiCreateComboBox(x, y, w, h, "", false, parent)
	elseif(tpl.type == "list") then
		ctrl = guiCreateGridList(x, y, w, h, false, parent)
		if(tpl.sorting == "false") then
			guiGridListSetSortingEnabled(ctrl, false)
		end
	elseif(tpl.type == "column") then
		ctrl = guiGridListAddColumn(parent, tpl.text or "", tpl.w or 0.5)
	else
		assert(false)
	end
	
	if(tpl.visible == "false") then
		guiSetVisible(ctrl, false)
	end
	if(tpl.alpha) then
		guiSetAlpha(ctrl, (tonumber(tpl.alpha) or 255)/255)
	end
	if(tpl.font) then
		guiSetFont(ctrl, tpl.font)
	end
	if(tpl.enabled == "false") then
		guiSetEnabled(ctrl, false)
	end
	
	if(tpl.id) then
		self[tpl.id] = ctrl
	end
	if(tpl.focus == "true") then
		self.focus = ctrl
	end
	if(tpl.defbtn) then
		addEventHandler("onClientGUIAccepted", ctrl, GUI.onAccept, false)
	end
	
	return ctrl
end

function GUI.__mt.__index:createControls(tpl, parent)
	local wnd = self:createControl(tpl, parent)
	for i, childTpl in ipairs(tpl) do
		local ctrl = self:createControls(childTpl, wnd)
		if(isElement(ctrl)) then -- dont insert columns
			self.ctrlList[ctrl] = childTpl
		end
	end
	return wnd
end

function GUI.__mt.__index:destroy(ignoreEl)
	if(not ignoreEl) then
		destroyElement(self.wnd)
	end
	self.ctrlList = false
	self.tpl = false
	
	GUI.wndToObj[self.wnd] = nil
	self.wnd = false
end

function GUI.onResize()
	local self = GUI.wndToObj[source]
	local w, h = guiGetSize(source, false)
	local minw, minh = tonumber(self.tpl.minw), tonumber(self.tpl.minh)
	local resize = false
	if(minw and w < minw) then
		w = minw
		resize = true
	elseif(minh and h < minh) then
		h = minh
		resize = true
	end
	
	if(resize) then
		guiSetSize(source, w, h, false)
	end
	
	for ctrl, tpl in pairs(self.ctrlList) do
		local parent = getElementParent(ctrl)
		local rc = GUI.computeCtrlPlacement(tpl, parent)
		local x, y, w, h = rc[1][1], rc[1][2], rc[2][1], rc[2][2]
		guiSetPosition(ctrl, x, y, false)
		guiSetSize(ctrl, w, h, false)
	end
end

function GUI.onAccept()
	local parent = getElementParent(source)
	local self = GUI.wndToObj[parent]
	local tpl = self.ctrlList[source]
	local btn = self[tpl.defbtn]
	if(btn and guiGetEnabled(btn)) then
		triggerEvent("onClientGUIClick", btn, "left", "up")
	end
end

function GUI.onDestroy()
	local self = GUI.wndToObj[source]
	if(self) then
		self:destroy(true)
	end
end

function GUI.create(tpl, x, y, w, h, parent)
	if(type(tpl) ~= "table") then
		tpl = GUI.getTemplate(tpl)
		if(not tpl) then
			outputDebugString("Unknown template ID "..tostring(tpl), 1)
			return false
		end
	end
	
	if(x and y and w and h) then
		tpl = table.copy(tpl)
		tpl.x, tpl.y = x, y
		tpl.w, tpl.h = w, h
		tpl.rx, tpl.ry, tpl.rh, tpl.rw = 0, 0, 0, 0
	end
	
	local self = setmetatable({}, GUI.__mt)
	self.parent = parent
	self.tpl = tpl
	self.ctrlList = {}
	self.wnd = self:createControls(self.tpl, parent)
	if(not self.focus) then
		self.focus = self.wnd
	end
	addEventHandler("onClientGUISize", self.wnd, GUI.onResize, false)
	addEventHandler("onClientElementDestroy", self.wnd, GUI.onDestroy, false)
	guiBringToFront(self.focus)
	
	GUI.wndToObj[self.wnd] = self
	return self
end
