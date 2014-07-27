namespace('MemeBrowser')

local g_Gui
local g_Services = {
	{id = 'demotywatory', title = 'Demotywatory.pl'},
	{id = 'kwejk', title = 'Kwejk.pl'},
}

local function repositionItems()
	local w, h = guiGetSize(g_Gui.scrollPane, false)
	local y = 0
	for i = 1, 20 do
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

function addImage(page, index, title, data)
	if (page ~= g_Page) then return end
	
	local path = 'meme_browser/cache/img'..index..'.jpg'
	fileSetContents(path, data)
	
	title = title:gsub('%s+', ' ')
	
	if (g_Gui) then
		local item = g_Gui.items[index]
		local w, h = guiGetSize(g_Gui.scrollPane, false)
		local maxImgW = w - 10
		local maxImgH = h
		
		if (not item) then
			item = {}
			
			item.title = guiCreateLabel(0, 350 * (index - 1), w - 10, 300, title, false, g_Gui.scrollPane)
			guiSetFont(item.title, 'default-bold-small')
			
			item.img = guiCreateStaticImage(0, 350 * (index - 1) + 20, 400, 300, path, false, g_Gui.scrollPane)
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
			end
			
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
	RPC('MemeBrowser.requestImages', service.id, page):exec()
	
	for index, item in pairs(g_Gui.items) do
		destroyElement(item.title)
		if (item.img) then
			destroyElement(item.img)
		end
	end
	g_Gui.items = {}
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

addEventHandler('onClientResourceStart', resourceRoot, init)
