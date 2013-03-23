local g_BannedNames = {}

local function NbCheckName(name)
	local plainName = name:lower():gsub("#%x%x%x%x%x%x", "")
	if(plainName == "") then return true end -- empty is banned
	
	for i, pattern in ipairs(g_BannedNames) do
		if(plainName:match(pattern)) then
			return true
		end
	end
	
	return false
end

function NbGenerateUniqueName()
	local name = "ToxicPlayer"
	local i = 1
	while(getPlayerFromName(name)) do
		i = i + 1
		name = "ToxicPlayer"..i
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
	local node, i = xmlLoadFile("conf/banned_names.xml"), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, "name", i)
			if(not subnode) then break end
			i = i + 1
			
			local pattern = xmlNodeGetValue(subnode)
			assert(pattern)
			table.insert(g_BannedNames, pattern)
		end
		xmlUnloadFile(node)
	end
end

addInitFunc(NbInit)
