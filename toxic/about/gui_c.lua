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

local function initAboutPane(x, y, w, h, panel)
	local scrollPane = guiCreateScrollPane(x, y, w, h, false, panel)
	
	local node = xmlLoadFile("conf/about.xml")
	if(not node) then return false end
	
	local subnodes = xmlNodeGetChildren(node)
	local c = math.floor(#subnodes/2)
	local x, y = 10, 15
	local col = 1
	
	local prevAttr
	local lines = {}
	
	for i = 1, #subnodes + 1 do
		local subnode = subnodes[i]
		local text = subnode and xmlNodeGetValue(subnode)
		local attr = subnode and xmlNodeGetAttributes(subnode)
		
		if(attr and attr[Settings.locale]) then
			text = attr[Settings.locale]
		end
		
		local br = false
		if(col == 1 and i > c and text == "") then
			br = true
			col = 2
		end
		
		local styleChanged = prevAttr and attr and (prevAttr.bold ~= attr.bold or prevAttr.color ~= attr.color)
		
		if(styleChanged or br or not subnode) then
			local linesStr = table.concat(lines, "\n")
			
			local label = guiCreateLabel(x, y, 160, 15, linesStr, false, scrollPane)
			
			if(prevAttr.bold == "true") then
				guiSetFont(label, "default-bold-small")
			end
			
			if(prevAttr.color) then
				local r, g, b = getColorFromString(prevAttr.color)
				if(r) then
					guiLabelSetColor(label, r, g, b)
				end
			end
			
			local fontH = guiLabelGetFontHeight(label)
			local linesH = fontH*#lines
			guiSetSize(label, 160, linesH, false)
			y = y + linesH
			lines = {}
		end
		prevAttr = attr
		
		if(br) then
			x = 160
			y = 15
		elseif(text) then
			table.insert(lines, text)
		end
	end
	xmlUnloadFile(node)
	
	return true
end

local function createGui(panel)
	local w, h = guiGetSize(panel, false)
	
	guiCreateStaticImage(10, 10, 200, 64, "about/logo.jpg", false, panel)
	
	local label = guiCreateLabel(10, 80, w - 20, 15, "About ToxiC Server", false, panel)
	guiLabelSetColor(label, 0, 255, 0)
	guiSetFont(label, "default-bold-small")
	
	local paneH = h - 110
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(w - 90, h - 35, 80, 25, "Back", false, panel)
		addEventHandler("onClientGUIClick", btn, UpBack, false)
		paneH = paneH - 40
	end
	
	initAboutPane(10, 100, w - 20, paneH, panel)
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
