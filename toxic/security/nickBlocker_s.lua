local g_BannedNames = {}

function NbCheckName(name)
	--outputDebugString('NbCheckName '..name, 3)
	local plainName = name:lower():gsub('#%x%x%x%x%x%x', '')
	if(plainName == '') then return true end -- empty is banned
	
	for i, pattern in ipairs(g_BannedNames) do
		if(plainName:match(pattern)) then
			return true
		end
	end
	
	if(CsCheckNickname and CsCheckNickname(plainName)) then
		return true
	end
	
	return false
end

function NbGenerateUniqueName()
	local name = 'ToxicPlayer'
	local i = 1
	while(getPlayerFromName(name)) do
		i = i + 1
		name = 'ToxicPlayer'..i
	end
	return name
end

function NbCheckPlayerAndFix(player)
	local name = getPlayerName(player)
	if(not NbCheckName(name)) then return end
	
	local newName = NbGenerateUniqueName()
	setPlayerName(player, newName)
end

local function NbInit()
	-- Note: called before players are created
	local node = xmlLoadFile('conf/banned_names.xml')
	if(node) then
		for i, subnode in ipairs(xmlNodeGetChildren(node)) do
			local pattern = xmlNodeGetValue(subnode)
			assert(pattern)
			table.insert(g_BannedNames, pattern)
		end
		xmlUnloadFile(node)
	end
end

addPreInitFunc(NbInit)
