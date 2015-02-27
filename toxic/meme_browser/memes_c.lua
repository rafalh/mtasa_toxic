namespace('MemeBrowser')

local g_Gui
local g_Services = {
	{id = 'demotywatory', title = 'Demotywatory.pl'},
	{id = 'kwejk', title = 'Kwejk.pl'},
}
local g_MaxIndex = 0

local function repositionItems()
	local w, h = guiGetSize(g_Gui.scrollPane, false)
	local y = 0
	for i = 1, g_MaxIndex do
		local item = g_Gui.items[i]
		if (item) then
			guiSetPosition(item.title, 0, y, false)
			if (item.img) then
				local imgW, imgH = guiGetSize(item.img, false)
				guiSetPosition(item.img, (w - imgW)/2, y + 20, false)
				y = y + 20 + imgH + 20
			else
				y = y + 20
			end
		end
	end
end

local function resizeItem(item, w, h)
	local maxImgW = w - 10
	local maxImgH = h
	
	local titleW = w - 10
	if (item.img) then
		local imgW, imgH = guiStaticImageGetNativeSize(item.img)
		if (imgW > maxImgW) then
			-- scale
			imgH = imgH / imgW * maxImgW
			imgW = maxImgW
		end
		if (imgH > maxImgH) then
			imgW = imgW / imgH * maxImgH
			imgH = maxImgH
		end
		guiSetSize(item.img, imgW, imgH, false)
		titleW = math.max(titleW, imgW)
	end
	guiSetSize(item.title, titleW, 15, false)
end

local function resizeItems()
	local w, h = guiGetSize(g_Gui.scrollPane, false)
	for i = 1, g_MaxIndex do
		local item = g_Gui.items[i]
		if (item) then
			resizeItem(item, w, h)
		end
	end
	
	repositionItems()
end

-- RPC
function addImage(page, index, title, data)
	if (page ~= g_Page) then return end
	
	local path = 'meme_browser/cache/img'..index..'.jpg'
	fileSetContents(path, data)
	
	title = title:gsub('%s+', ' ')
	
	g_MaxIndex = math.max(g_MaxIndex, index)
	
	if (g_Gui) then
		local item = g_Gui.items[index]
		local w, h = guiGetSize(g_Gui.scrollPane, false)
		
		if (not item) then
			item = {}
			
			item.title = guiCreateLabel(0, 350 * (index - 1), w - 10, 15, title, false, g_Gui.scrollPane)
			guiSetFont(item.title, 'default-bold-small')
			guiLabelSetHorizontalAlign(item.title, 'center', false)
			item.img = guiCreateStaticImage(0, 350 * (index - 1) + 20, 400, 300, path, false, g_Gui.scrollPane)
			resizeItem(item, w, h)
			
			g_Gui.items[index] = item
		else
			guiStaticImageLoadImage(item.img, path)
			guiSetText(item.title, title)
		end
		
		repositionItems()
	end
end

local function requestImages(page)
	local service = g_Services[guiComboBoxGetSelected(g_Gui.serviceComboBox) + 1]
	if (not service) then return end
	
	g_Page = page
	
	-- Remove actual images
	for index, item in pairs(g_Gui.items) do
		destroyElement(item.title)
		if (item.img) then
			destroyElement(item.img)
		end
	end
	guiScrollPaneSetHorizontalScrollPosition(g_Gui.scrollPane, 0)
	guiScrollPaneSetVerticalScrollPosition(g_Gui.scrollPane, 0)
	g_Gui.items = {}
	
	-- Request new images
	RPC('MemeBrowser.requestImages', service.id, page):exec()
end

function previousPage()
	local num = touint(guiGetText(g_Gui.numEdit), 0)
	if (num > 1) then
		num = num - 1
	elseif (num < 1) then
		num = 1
	end
	guiSetText(g_Gui.numEdit, tostring(num))
	requestImages(num)
end

function nextPage()
	local num = touint(guiGetText(g_Gui.numEdit), 0)
	num = num + 1
	guiSetText(g_Gui.numEdit, tostring(num))
	requestImages(num)
end

function randomImage()
	guiSetText(g_Gui.numEdit, '')
	requestImages(false)
end

local function handleServiceChange()
	guiSetText(g_Gui.numEdit, '1')
	requestImages(1)
end

function show()
	if (g_Gui) then return end
	
	g_Gui = GUI.create('memeBrowser')
	g_Gui.items = {}
	
	addEventHandler('onClientGUIClick', g_Gui.closeBtn, hide, false)
	addEventHandler('onClientGUIClick', g_Gui.prevBtn, previousPage, false)
	addEventHandler('onClientGUIClick', g_Gui.nextBtn, nextPage, false)
	addEventHandler('onClientGUIClick', g_Gui.randomBtn, randomImage, false)
	addEventHandler('onClientGUISize', g_Gui.wnd, resizeItems, false)
	
	for i, service in ipairs(g_Services) do
		guiComboBoxAddItem(g_Gui.serviceComboBox, service.title)
	end
	guiComboBoxSetSelected(g_Gui.serviceComboBox, 0)
	addEventHandler('onClientGUIComboBoxAccepted', g_Gui.serviceComboBox, handleServiceChange)
	handleServiceChange()
	
	showCursor(true)
end

function hide()
	if (not g_Gui) then return end
	
	g_Gui:destroy()
	g_Gui = false
	showCursor(false)
end

local function toggleBrowser()
	if (g_Gui) then
		hide()
	else
		show()
	end
end

local function init()
	addCommandHandler('memes', toggleBrowser, false)
	GUI.loadTemplates('meme_browser/gui.xml')
end

UpRegister {
	name = "Meme browser",
	img = 'meme_browser/icon.jpg',
	tooltip = "Browse newest internet memes.",
	noWnd = true,
	onShow = function(panel)
		show()
		return true
	end,
}

addEventHandler('onClientResourceStart', resourceRoot, init)
