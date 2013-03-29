---------------------
-- Local variables --
---------------------

local g_Panel = nil

local AboutPanel = {
	name = "About",
	img = "about/icon.png",
	tooltip = "Learn more about this server",
}

--------------------------------
-- Local function definitions --
--------------------------------

local function initAboutPane(panel)
	local w, h = guiGetSize(panel, false)
	local scrollPane = guiCreateScrollPane(120, 30, w - 130, h - 70, false, panel)
	
	local node = xmlLoadFile("conf/about.xml")
	if(not node) then return false end
	
	local subnodes = xmlNodeGetChildren(node)
	local c = math.floor(#subnodes/2)
	local x, y = 10, 15
	
	for i, subnode in ipairs(subnodes) do
		local text = xmlNodeGetValue(subnode)
		local attr = xmlNodeGetAttributes(subnode)
		
		if(attr[Settings.locale]) then
			text = attr[Settings.locale]
		end
		
		if(text ~= "") then
			-- removed hack - make label 20 px bigger too make size for scrollbars
			local label = guiCreateLabel(x, y, 160, 15, text, false, scrollPane)
			y = y + 15
			
			if(attr.bold == "true") then
				guiSetFont(label, "default-bold-small")
			end
			
			if(attr.color) then
				local r, g, b = getColorFromString(attr.color)
				if(r) then
					guiLabelSetColor(label, r, g, b)
				end
			end
		elseif(i > c and x == 10) then
			x = 160
			y = 15
		else
			y = y + 15
		end
		--local w = guiLabelGetTextExtent(label)
		--outputChatBox(w)
		--guiSetSize(label, w, 15)
	end
	xmlUnloadFile(node)
	return true
end

local function createGui(panel)
	DbgPerfInit()
	
	local w, h = guiGetSize(panel, false)
	
	guiCreateStaticImage(10, 10, 100, 75, "about/logo.jpg", false, panel)
	
	local label = guiCreateLabel(120, 10, w - 130, 15, "About ToxiC Server", false, panel)
	guiLabelSetColor(label, 0, 255, 0)
	guiSetFont(label, "default-bold-small")
	
	initAboutPane(panel)
	
	guiCreateLabel(10, h - 25, w - 100, 15, "Copyright (c) 2009-2013 by rafalh", false, panel)
	
	local btn = guiCreateButton(w - 90, h - 35, 80, 25, "Back", false, panel)
	addEventHandler("onClientGUIClick", btn, UpBack, false)
	
	DbgPerfCp("About server GUI creation")
end

function AboutPanel.onShow(panel)
	if(not g_Panel) then
		g_Panel = panel
		createGui(panel)
	end
	AchvActivate("Read about the server")
end

----------------------
-- Global variables --
----------------------

UpRegister(AboutPanel)
