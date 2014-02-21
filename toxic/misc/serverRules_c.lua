namespace('ServerRules')

local g_Rules = false
local g_GUI

local function load()
	local node = xmlLoadFile('conf/server_rules.xml')
	if(not node) then
		outputDebugString('Failed to load server_rules.xml', 2)
		return false
	end
	
	g_Rules = {[false] = {}}
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		local lang = attr.lang ~= '*' and attr.lang
		local text = xmlNodeGetValue(subnode)
		local tbl = split(trimStr(text), '\n')
		for i, str in ipairs(tbl) do
			tbl[i] = trimStr(str)
		end
		g_Rules[lang] = tbl
	end
	
	xmlUnloadFile(node)
	return true
end

local function hide()
	g_GUI:destroy()
	g_GUI = false
	showCursor(false)
end

function display()
	if(g_GUI) then return end
	
	if(not g_Rules) then
		load()
	end
	
	local prof = DbgPerf(100)
	
	g_GUI = GUI.create('serverRules')
	local numW = guiGetSize(g_GUI.numbers, false)
	local ruleW = guiGetSize(g_GUI.rules, false)
	local font = guiGetFont(g_GUI.rules)
	
	local rules = g_Rules[Settings.locale] or g_Rules[false]
	local rulesTbl, numbersTbl = {}, {}
	for i, rule in ipairs(rules) do
		local tbl = GUI.wordWrap(rule, ruleW, font)
		for i, str in ipairs(tbl) do
			table.insert(rulesTbl, str)
		end
		table.insert(numbersTbl, i..'.'..('\n'):rep(#tbl - 1))
	end
	
	local h = GUI.getFontHeight(font) * #rulesTbl
	guiSetSize(g_GUI.rules, ruleW, h, false)
	guiSetSize(g_GUI.numbers, numW, h, false)
	
	local numbersStr = table.concat(numbersTbl, '\n')
	local rulesStr = table.concat(rulesTbl, '\n')
	guiSetText(g_GUI.numbers, numbersStr)
	guiSetText(g_GUI.rules, rulesStr)
	
	addEventHandler('onClientGUIClick', g_GUI.ok, hide, false)
	showCursor(true)
	
	prof:cp('ServerRules.display')
end

addCommandHandler('rules', display, false)
