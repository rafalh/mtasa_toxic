namespace('ServerRules')

local g_Rules = false
local g_MsgBox

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
		local tbl = split(text, '\n')
		for i, str in ipairs(tbl) do
			str = trimStr(str)
			local idxStr = tostring(i)
			if(str:sub(1, idxStr:len()) ~= idxStr) then
				str = idxStr..'. '..str
			end
			tbl[i] = str
		end
		g_Rules[lang] = tbl
	end
	
	xmlUnloadFile(node)
	return true
end

function display()
	if(g_MsgBox and g_MsgBox:isVisible()) then return end
	
	if(not g_Rules) then
		load()
	end
	
	local rules = g_Rules[Settings.locale] or g_Rules[false]
	local text = table.concat(rules, '\n')
	g_MsgBox = MsgBox("Server Rules", text, 'info')
	g_MsgBox:show()
end

addCommandHandler('rules', display, false)
