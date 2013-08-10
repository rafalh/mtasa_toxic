-- Settings
#HAVE_HOVER_IMG = true
local LABEL_COLOR = {0, 0, 0}

-- Globals
local g_LabelFromBtn = {}
local g_TempHoverImg, g_TempHoverLabel
local g_ActiveImg

local hoverProc

local function guiGetPosOnScreen(el)
	local x, y = guiGetPosition(el, false)
	local parent = getElementParent(el)
	if(isElement(parent) and getElementType(parent) ~= 'guiroot' and parent ~= g_Root) then
		local px, py = guiGetPosOnScreen(parent)
		x, y = x + px, y + py
	end
	return x, y
end

local function createBtnGUI(x, y, w, h, text, imgPath, relative, parent)
	local img = guiCreateStaticImage(x, y, w, h, imgPath, relative, parent)
	
	local label = guiCreateLabel(0, 0, 1, 0.9, text, true, img)
	guiLabelSetHorizontalAlign(label, 'center')
	guiLabelSetVerticalAlign(label, "center")
	guiLabelSetColor(label, unpack(LABEL_COLOR))
	guiSetFont(label, 'default-bold-small')
	guiSetProperty(label, 'MousePassThroughEnabled', 'True')
	
	return img, label
end

local function stopHover()
	if(not g_ActiveImg) then return end
	guiSetVisible(g_TempHoverImg, false)
	removeEventHandler('onClientPreRender', root, hoverProc)
	g_ActiveImg = false
end

hoverProc = function()
	if(not isCursorShowing() or not isElement(g_ActiveImg) or not guiGetVisible(g_ActiveImg)) then
		stopHover()
	end
end

local function onButtonMouseLeave()
	local img = source
	if(getElementType(img) ~= "gui-staticimage") then
		img = getElementParent(img)
	end
#if(HAVE_HOVER_IMG) then
	--guiStaticImageLoadImage(img, "button_theme/button.png")
	stopHover()
#else
	guiSetAlpha(img, 0.8)
#end
end

local function onButtonMouseEnter()
	local img = source
	if(getElementType(img) ~= 'gui-staticimage') then
		img = getElementParent(img)
	end
	
#if(HAVE_HOVER_IMG) then
	local x, y = guiGetPosOnScreen(img)
	local w, h = guiGetSize(img, false)
	local label = g_LabelFromBtn[img]
	local text = guiGetText(label)
	
	-- Note: setElementParent doesn't move GUI elements
	if(not g_TempHoverImg) then
		g_TempHoverImg, g_TempHoverLabel = createBtnGUI(x, y, w, h, text, 'button_theme/buttonHover.png', false)
		guiSetProperty(g_TempHoverImg, 'MousePassThroughEnabled', 'True')
		guiSetProperty(g_TempHoverImg, 'AlwaysOnTop', 'True')
		
		addEventHandler('onClientMouseLeave', g_TempHoverImg, onButtonMouseLeave, false)
		addEventHandler('onClientMouseLeave', g_TempHoverLabel, onButtonMouseLeave, false)
	else
		guiSetSize(g_TempHoverImg, w, h, false)
		guiSetPosition(g_TempHoverImg, x, y, false)
		guiSetText(g_TempHoverLabel, text)
		guiSetVisible(g_TempHoverImg, true)
	end
	
	if(not g_ActiveImg) then
		addEventHandler('onClientPreRender', root, hoverProc)
	end
	g_ActiveImg = img
	
	--guiStaticImageLoadImage(img, 'button_theme/buttonHover.png')
#else
	guiSetAlpha(img, 1)
#end
end

local function onButtonDestroy()
	g_LabelFromBtn[source] = nil
end

local _guiCreateButton = guiCreateButton
function guiCreateButton(x, y, width, height, text, relative, parent)
	local img, label = createBtnGUI(x, y, width, height, text, 'button_theme/button.png', relative, parent)
#if(not HAVE_HOVER_IMG) then
	guiSetAlpha(img, 0.8)
#end
	
	addEventHandler('onClientMouseEnter', img, onButtonMouseEnter, false)
	addEventHandler('onClientMouseLeave', img, onButtonMouseLeave, false)
	addEventHandler('onClientMouseEnter', label, onButtonMouseEnter, false)
	addEventHandler('onClientMouseLeave', label, onButtonMouseLeave, false)
	addEventHandler('onClientElementDestroy', img, onButtonDestroy, false)
	g_LabelFromBtn[img] = label
	return img
end

local _guiSetText = guiSetText
function guiSetText(el, text)
	local label = g_LabelFromBtn[el]
	if(not label) then _guiSetText(el, text)
	else _guiSetText(label, text) end
end
