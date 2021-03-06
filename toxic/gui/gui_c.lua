namespace('GUI') -- FIXME: to nie jest tu uzywane - trzeba by zrobic jakis obiekt GUI.Teplate
GUI.__mt = {__index = {}}
GUI.templates = false
GUI.wndToObj = {}

local g_ScrSize = Vector2(guiGetScreenSize())
local g_MainTplLoaded = false

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
		Debug.warn('xmlLoadFile '..path..' failed')
		return false
	end
	
	if (not GUI.templates) then
		GUI.templates = {}
	end
	
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
	if(not g_MainTplLoaded) then
		if(GUI.loadTemplates('gui/gui.xml')) then
			g_MainTplLoaded = true
		else
			Debug.err('Failed to load main GUI template')
		end
	end
	
	local tpl = GUI.templates[tplID]
	if (not tpl) then
		Debug.err('Cannot find template '..tostring(tplID))
	end
	return tpl
end

function GUI.__mt.__index:createControl(tpl, parent)
	local x, y, w, h = 0, 0, 0, 0
	local setupPos = true
	
	local ctrl
	if(tpl.type == 'window') then
		ctrl = guiCreateWindow(x, y, w, h, tpl.title or '', false)
		if(tpl.sizeable == 'false') then
			guiWindowSetSizable(ctrl, false)
		end
	elseif(tpl.type == 'button') then
		ctrl = guiCreateButton(x, y, w, h, tpl.text or '', false, parent)
	elseif(tpl.type == 'checkbox') then
		ctrl = guiCreateCheckBox(x, y, w, h, tpl.text or '', tpl.selected == 'true', false, parent)
	elseif(tpl.type == 'radiobutton') then
		ctrl = guiCreateRadioButton(x, y, w, h, tpl.text or '', false, parent)
		if(tpl.selected == 'true') then
			guiRadioButtonSetSelected(ctrl, true)
		end
	elseif(tpl.type == 'edit') then
		ctrl = guiCreateEdit(x, y, w, h, tpl.text or '', false, parent)
		if (tpl.readonly == 'true') then
			guiEditSetReadOnly(ctrl, true)
		end
		if(tonumber(tpl.maxlen)) then
			guiEditSetMaxLength(ctrl, tonumber(tpl.maxlen))
		end
		if(tpl.masked == 'true') then
			guiEditSetMasked(ctrl, true)
		end
		if(tpl.pattern) then
			guiSetProperty(ctrl, 'ValidationString', tpl.pattern)
		end
	elseif(tpl.type == 'memo') then
		ctrl = guiCreateMemo(x, y, w, h, tpl.text or '', false, parent)
		if(tpl.readonly == 'true') then
			guiMemoSetReadOnly(ctrl, true)
		end
	elseif(tpl.type == 'label') then
		ctrl = guiCreateLabel(x, y, w, h, tpl.text or '', false, parent)
		if(tpl.align) then
			guiLabelSetHorizontalAlign(ctrl, tpl.align, tpl.wordwrap == 'true')
		end
		if(tpl.color) then
			local r, g, b = getColorFromString(tpl.color)
			guiLabelSetColor(ctrl, r or 255, g or 255, b or 255)
		end
	elseif(tpl.type == 'image') then
		ctrl = guiCreateStaticImage(x, y, w, h, tpl.src or '', false, parent)
	elseif(tpl.type == 'combobox') then
		ctrl = guiCreateComboBox(x, y, w, h, '', false, parent)
	elseif(tpl.type == 'list') then
		ctrl = guiCreateGridList(x, y, w, h, false, parent)
		if(tpl.sorting == 'false') then
			guiGridListSetSortingEnabled(ctrl, false)
		end
	elseif(tpl.type == 'column') then
		local w = tpl.rc:getAbs()[2][1]
		ctrl = guiGridListAddColumn(parent, tpl.text or '', w == 0 and 0.5 or w)
		setupPos = false
	elseif(tpl.type == 'tabpanel') then
		ctrl = guiCreateTabPanel(x, y, w, h, false, parent)
	elseif(tpl.type == 'scrollpane') then
		ctrl = guiCreateScrollPane(x, y, w, h, false, parent)
	elseif(tpl.type == 'browser') then
		ctrl = guiCreateBrowser(x, y, w, h, tpl.islocal == 'true', tpl.istransparent == 'true', false, parent)
	elseif(tpl.type == 'tab') then
		ctrl = guiCreateTab(tpl.text, parent)
		if(tpl.selected) then
			guiSetSelectedTab(parent, ctrl)
		end
		setupPos = false
	elseif(type(_G[tpl.type]) == 'table' and _G[tpl.type].fromTpl) then
		local cls = _G[tpl.type]
		ctrl = cls.fromTpl(tpl, parent)
	else
		assert(false, 'Unknown control type '..tostring(tpl.type))
	end
	
	if(setupPos) then
		local absRc, relRc = tpl.rc:getAbs(), tpl.rc:getRel()
		local unifiedRect = '{'..
			'{'..(relRc[1][1]/100)..','..absRc[1][1]..'},'.. -- left
			'{'..(relRc[1][2]/100)..','..absRc[1][2]..'},'.. -- top
			'{'..((relRc[1][1]+relRc[2][1])/100)..','..(absRc[1][1]+absRc[2][1])..'},'.. -- right
			'{'..((relRc[1][2]+relRc[2][2])/100)..','..(absRc[1][2]+absRc[2][2])..'}'.. -- bottom
			'}'
		guiSetProperty(ctrl, 'UnifiedAreaRect', unifiedRect)
		
		local minW, minH = tonumber(tpl.minw) or 0, tonumber(tpl.minh) or 0
		if(minW > 0 or minH > 0) then
			guiSetProperty(ctrl, 'UnifiedMinSize', '{{0,'..minW..'},{0,'..minH..'}}')
		end
	end
	
	if(tpl.visible == 'false') then
		guiSetVisible(ctrl, false)
	end
	if(tpl.alpha) then
		guiSetAlpha(ctrl, (tonumber(tpl.alpha) or 255)/255)
	end
	if(tpl.font) then
		guiSetFont(ctrl, tpl.font)
	end
	if(tpl.enabled == 'false') then
		guiSetEnabled(ctrl, false)
	end
	
	if(tpl.id) then
		self[tpl.id] = ctrl
	end
	if(tpl.focus == 'true') then
		self.focus = ctrl
	end
	if(tpl.defbtn or self.tpl.defbtn) then
		addEventHandler('onClientGUIAccepted', ctrl, GUI.onAccept, false)
	end
	if(tpl.type == 'browser') then
		-- fix size of wrapped browser
		local w, h = guiGetSize(ctrl, false)
		guiSetSize(ctrl, w, h, false)
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

function GUI.onAccept()
	local parent = getElementParent(source)
	local self = GUI.wndToObj[parent]
	local tpl = self.ctrlList[source]
	local btn = self[tpl.defbtn or self.tpl.defbtn]
	if(btn and guiGetEnabled(btn)) then
		triggerEvent('onClientGUIClick', btn, 'left', 'up')
	end
end

function GUI.onDestroy()
	local self = GUI.wndToObj[source]
	if(self) then
		self:destroy(true)
	end
end

function GUI.create(tpl, x, y, w, h, parent)
	if(type(tpl) ~= 'table') then
		tpl = GUI.getTemplate(tpl)
		if(not tpl) then
			return false
		end
	end
	
	if(x and y and w and h) then
		tpl = table.copy(tpl)
		tpl.rc = RelRect(Rect(Vector2(x, y), Vector2(w, h)))
	end
	
	local self = setmetatable({}, GUI.__mt)
	self.parent = parent
	self.tpl = tpl
	self.ctrlList = {}
	self.wnd = self:createControls(self.tpl, parent)
	if(not self.focus) then
		self.focus = self.wnd
	end
	
	addEventHandler('onClientElementDestroy', self.wnd, GUI.onDestroy, false)
	guiBringToFront(self.focus)
	
	GUI.wndToObj[self.wnd] = self
	return self
end
