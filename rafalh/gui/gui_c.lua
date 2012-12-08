GUI = {}
GUI.__mt = {__index = GUI}
GUI.templates = false

function GUI.loadNode(node)
	local ctrl = xmlNodeGetAttributes(node)
	ctrl.type = xmlNodeGetName(node)
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
	local pw, ph
	if(parent) then
		pw, ph = dxGetSize(parent)
	else
		pw, ph = guiGetScreenSize()
	end
	
	local x, y = tpl.x or 0, tpl.y or 0
	local w, h = tpl.w or 0, tpl.h or 0
	x = x + (tpl.rx or 0) * pw / 100
	y = y + (tpl.ry or 0) * ph / 100
	w = w + (tpl.rw or 0) * pw / 100
	h = h + (tpl.rh or 0) * ph / 100
	
	return x, y, w, h
end

function GUI:createControl(tpl, parent)
	local x, y, w, h = GUI.computeCtrlPlacement(tpl, parent)
	
	local ctrl
	if ( tpl.type == "window") then
		ctrl = guiCreateWindow(x, y, w, h, tpl.title or "")
		if(tpl.sizeable == "false") then
			--guiWindowSetSizable(ctrl, false)
		end
	elseif(tpl.type == "button") then
		ctrl = guiCreateButton(x, y, w, h, tpl.text or "", parent)
	elseif(tpl.type == "checkbox") then
		ctrl = guiCreateCheckBox(x, y, w, h, tpl.text or "", tpl.selected == "true", parent)
	elseif(tpl.type == "edit") then
		ctrl = guiCreateEdit(x, y, w, h, tpl.text or "", parent)
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
		ctrl = guiCreateMemo(x, y, w, h, tpl.text or "", parent)
		if(tpl.readonly == "true") then
			guiMemoSetReadOnly(ctrl, true)
		end
	elseif(tpl.type == "label") then
		ctrl = guiCreateLabel(x, y, w, h, tpl.text or "", parent)
		if(tpl.align) then
			guiSetLabelAlign(ctrl, tpl.align)
		end
		if(tpl.color) then
			local r, g, b = getColorFromString(tpl.color)
			guiLabelSetColor(ctrl, r or 255, g or 255, b or 255)
		end
	elseif(tpl.type == "image") then
		ctrl = dxCreateImage(x, y, w, h, tpl.src or "", parent)
	elseif(tpl.type == "list") then
		ctrl = guiCreateGridList(x, y, w, h, false, parent)
	elseif(tpl.type == "column") then
		ctrl = guiGridListAddColumn(parent, tpl.text or "", tpl.w or 0.5)
	else
		assert (false)
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
		dxSetEnabled(ctrl, false)
	end
	
	if(tpl.id) then
		self[tpl.id] = ctrl
	end
	if(tpl.focus == "true") then
		self.focus = ctrl
	end
	if(tpl.defbtn) then
		addEventHandler("onClientGUIAccepted", ctrl, function()
			local btn = self[tpl.defbtn]
			if(btn) then
				triggerEvent("onClientGUIClick", btn, "left", "up")
			end
		end, false)
	end
	
	return ctrl
end

function GUI:createControls(tpl, parent)
	local ctrl = self:createControl(tpl, parent)
	for i, childTpl in ipairs(tpl) do
		self:createControl(childTpl, ctrl)
	end
	return ctrl
end

function GUI:destroy()
	destroyElement(self.wnd)
end

function GUI.create(id, parent)
	local self = setmetatable({}, GUI.__mt)
	self.parent = parent
	
	self.tpl = GUI.getTemplate(id)
	if(not self.tpl) then
		outputDebugString("Unknown template ID "..id, 1)
		return false
	end
	
	self.wnd = self:createControls(self.tpl, parent)
	if(not self.focus) then
		self.focus = self.wnd
	end
	guiBringToFront(self.focus)
	
	return self
end
