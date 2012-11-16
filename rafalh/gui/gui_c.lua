local g_Templates = {}
local g_Windows = {}

local function GuiLoadNode ( node )
	local tpl = xmlNodeGetAttributes ( node )
	tpl.children = {}
	tpl.type = xmlNodeGetName ( node )
	
	for i, subnode in ipairs ( xmlNodeGetChildren ( node ) ) do
		table.insert ( tpl.children, GuiLoadNode ( subnode ) )
	end
	
	return tpl
end

function GuiLoad ( path )
	local node = xmlLoadFile ( path )
	if ( node ) then
		for i, subnode in ipairs ( xmlNodeGetChildren ( node ) ) do
			local tpl = GuiLoadNode ( subnode )
			if ( tpl.id ) then
				g_Templates[tpl.id] = tpl
			end
		end
		
		xmlUnloadFile ( node )
	else
		outputDebugString ( "xmlLoadFile "..path.." failed", 2 )
	end
end

local function GuiGetPlacement ( tpl, parent )
	local parent_w, parent_h
	if ( parent ) then
		parent_w, parent_h = guiGetSize ( parent, false )
	else
		parent_w, parent_h = guiGetScreenSize ()
	end
	
	local x, y, w, h = tpl.x, tpl.y, tpl.w, tpl.h
	if ( not w and x ) then
		w = parent_w - x - tpl.x2
	end
	if ( not h and y ) then
		h = parent_h - y - tpl.y2
	end
	if ( not x ) then
		if ( tpl.x2 ) then
			x = parent_w - w - tpl.x2
		elseif ( w ) then
			x = ( parent_w - w ) / 2
		end
	end
	if ( not y ) then
		if ( tpl.y2 ) then
			y = parent_h - h - tpl.y2
		elseif ( h ) then
			y = ( parent_h - h ) / 2
		end
	end
	
	return x, y, w, h
end

local function GuiCreateWndInternal ( tpl, parent )
	local x, y, w, h = GuiGetPlacement ( tpl, parent )
	
	local wnd
	if ( tpl.type == "window" ) then
		wnd = guiCreateWindow ( x, y, w, h, tpl.title or "", false )
	elseif ( tpl.type == "button" ) then
		wnd = guiCreateButton ( x, y, w, h, tpl.text or "", false, parent )
	elseif ( tpl.type == "edit" ) then
		wnd = guiCreateEdit ( x, y, w, h, tpl.text or "", false, parent )
		if ( tpl.readonly == "true" ) then
			guiEditSetReadOnly ( wnd, true )
		end
		if ( tonumber ( tpl.maxlen ) ) then
			guiEditSetMaxLength ( wnd, tonumber ( tpl.maxlen ) )
		end
		if ( tpl.color ) then
			-- TODO
		end
	elseif ( tpl.type == "memo" ) then
		wnd = guiCreateMemo ( x, y, w, h, tpl.text or "", false, parent )
		if ( tpl.readonly == "true" ) then
			guiMemoSetReadOnly ( wnd, true )
		end
	elseif ( tpl.type == "label" ) then
		wnd = guiCreateLabel ( x, y, w, h, tpl.text or "", false, parent )
	elseif ( tpl.type == "list" ) then
		wnd = guiCreateGridList ( x, y, w, h, false, parent )
	elseif ( tpl.type == "column" ) then
		wnd = guiGridListAddColumn ( parent, tpl.text or "", tpl.w or 0.5 )
	elseif ( tpl.type == "tpl" ) then
		--local tpl2 = g_Templates[tpl.id]
		--wnd = GuiCreateWndInternal ( tpl2, parent )
		wnd = GuiCreateWnd ( tpl.id, parent )
		guiSetPosition ( wnd, x, y, false )
		guiSetSize ( wnd, w, h, false )
	else
		assert ( false )
	end
	
	if ( tpl.visible == "false" ) then
		guiSetVisible ( wnd, false )
	end
	
	for i, subtpl in ipairs ( tpl.children ) do
		GuiCreateWndInternal ( subtpl, wnd )
	end
	return wnd
end

local function GuiResizeWndChildren ( wnd, tpl )
	local children = getElementChildren ( wnd )
	for i, child in ipairs ( children ) do
		local subtpl = tpl.children[i]
		assert ( subtpl )
		local x, y, w, h = GuiGetPlacement ( subtpl, wnd )
		guiSetPosition ( child, x, y, false )
		guiSetSize ( child, w, h, false )
		GuiResizeWndChildren ( child, subtpl )
	end
end

local function GuiOnWndResize ()
	GuiResizeWndChildren ( source, g_Windows[source] )
end

function GuiCreateWnd ( id, parent )
	assert ( g_Templates[id] )
	local wnd = GuiCreateWndInternal ( g_Templates[id], parent )
	g_Windows[wnd] = g_Templates[id]
	addEventHandler ( "onClientGUISize", wnd, GuiOnWndResize )
	return wnd
end

local function GuiGetCtrlInternal ( tpl, parent, id )
	local children = getElementChildren ( parent )
	
	for i, subtpl in ipairs ( tpl.children ) do
		if ( subtpl.id == id ) then
			return children[i]
		end
		if ( children[i] ) then
			GuiGetCtrlInternal ( subtpl, children[i], id )
		end
	end
end

function GuiGetCtrl ( wnd, id )
	if ( not g_Windows[wnd] ) then
		return false
	end
	return GuiGetCtrlInternal ( g_Windows[wnd], wnd, id )
end
