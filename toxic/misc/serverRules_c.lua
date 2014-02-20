namespace('ServerRules')

local g_Rules = false
local g_MsgBox

local function load()
	local file = fileOpen("conf/server_rules.txt", true)
	if(not file) then return false end
	
	local buf = fileRead(file, fileGetSize(file))
	fileClose(file)
	
	g_Rules = split(buf, '\n')
	for i, str in ipairs(g_Rules) do
		str = trimStr(str)
		local idxStr = tostring(i)
		if(str:sub(1, idxStr:len()) ~= idxStr) then
			str = idxStr..'. '..str
		end
		g_Rules[i] = str
	end
end

function display()
	if(g_MsgBox and g_MsgBox:isVisible()) then return end
	
	if(not g_Rules) then
		load()
	end
	
	g_MsgBox = MsgBox("Server Rules", table.concat(g_Rules, '\n'), 'info')
	g_MsgBox:show()
end

addCommandHandler('rules', display, false)
