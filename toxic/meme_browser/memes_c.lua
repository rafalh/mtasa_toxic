namespace('MemeBrowser')

local g_Gui
local g_Services = {
	{id = 'demotywatory', title = 'Demotywatory.pl'},
	{id = 'kwejk', title = 'Kwejk.pl'},
}

function addImage(index, title, data)
	local path = 'meme_browser/cache/img'..index..'.jpg'
	fileSetContents(path, data)
	
	if (g_Gui) then
		local item = g_Gui.items[index]
		local w, h = guiGetSize(g_Gui.scrollPane, false)
		if (not item) then
			item = {}
			item.title = guiCreateLabel(0, 350 * (index - 1), w - 10, 300, title, false, g_Gui.scrollPane)
			item.img = guiCreateStaticImage(0, 350 * (index - 1) + 20, 400, 300, path, false, g_Gui.scrollPane)
			guiSetFont(item.title, 'default-bold-small')
			g_Gui.items[index] = item
		else
			guiStaticImageLoadImage(item.img, path)
			guiSetText(item.title, title)
		end
	end
end

local function refresh()
	local service = g_Services[guiComboBoxGetSelected(g_Gui.serviceComboBox) + 1]
	if (service) then
		RPC('MemeBrowser.requestImages', service.id):exec()
	end
end

function show()
	if (g_Gui) then return end
	
	g_Gui = GUI.create('memeBrowser')
	g_Gui.items = {}
	
	addEventHandler('onClientGUIClick', g_Gui.closeBtn, hide, false)
	
	for i, service in ipairs(g_Services) do
		guiComboBoxAddItem(g_Gui.serviceComboBox, service.title)
	end
	guiComboBoxSetSelected(g_Gui.serviceComboBox, 0)
	addEventHandler('onClientGUIComboBoxAccepted', g_Gui.serviceComboBox, refresh)
	refresh()
	
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
