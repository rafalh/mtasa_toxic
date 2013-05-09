local g_ForbWords = {}

function CsProcessMsg(msg, player)
	if(not Settings.censor) then
		return 0, msg
	end
	
	local offsets = {}
	local offset = 0
	
	local buf = msg:lower():gsub("()%A", function(i) -- remove color codes
		offsets[i-offset] = i + 1
		offset = offset + 1
		return ""
	end)
	
	offset = 0
	for i = 1, buf:len()+1, 1 do
		if(not offsets[i]) then
			offsets[i] = offset + 1
		end
		offset = offsets[i]
	end
	
	local fine, hide, mute = 0, false, false
	
	for word, item in pairs(g_ForbWords) do
		local pattern = word:lower()
		pattern = pattern:gsub(".", "%1+")
		for i, j in buf:gmatch("()"..pattern.."()") do
			local before = msg:sub(1, offsets[i] - 1)
			local after = msg:sub(offsets[j])
			local masked = ("*"):rep(word:len())
			
			msg = before..masked..after -- change word to *****
			
			fine = math.max(fine, item.price)
			hide = hide or item.hide
			mute = mute or item.mute
		end
	end
	
	if(hide) then
		msg = false
		privMsg(player, "Your message contains disallowed content!")
	end
	
	if(mute) then
		local pdata = Player.fromEl(player)
		mutePlayer(pdata, 60)
	end
	
	return fine, msg
end

local function CsInit ()
	local node, i = xmlLoadFile("conf/censor.xml"), 0
	if(not node) then return end
	
	while(true) do
		local subnode = xmlFindChild(node, "word", i)
		if(not subnode) then break end
		i = i + 1
		
		local attr = xmlNodeGetAttributes(subnode)
		local word = xmlNodeGetValue(subnode)
		
		local item = {}
		item.price = touint(attr.price, 0)
		item.mute = tobool(attr.mute)
		item.hide = tobool(attr.hide)
		g_ForbWords[word] = item
	end
	xmlUnloadFile(node)
end

addInitFunc(CsInit)
