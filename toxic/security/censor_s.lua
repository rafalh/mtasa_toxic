local g_ForbWords = {}

function CsProcessMsg(msg)
	local offsets = {}
	local offset = 0
	
	local buf = msg:lower():gsub('()%A', function(i) -- remove color codes
		offsets[i-offset] = i + 1
		offset = offset + 1
		return ''
	end)
	
	offset = 0
	for i = 1, buf:len()+1, 1 do
		if(not offsets[i]) then
			offsets[i] = offset + 1
		end
		offset = offsets[i]
	end
	
	local punish = {fine = 0, mute = 0, warn = false, hide = false}
	local maskWords = Settings.censor_mask
	local found = false
	
	for word, item in pairs(g_ForbWords) do
		local pattern = word:lower()
		pattern = pattern:gsub('.', '%1+')
		for i, j in buf:gmatch('()'..pattern..'()') do
			-- Bad word has been found
			found = true
			
			if(maskWords) then
				-- Change word to *****
				local before = msg:sub(1, offsets[i] - 1)
				local after = msg:sub(offsets[j])
				local masked = ('*'):rep(word:len())
				msg = before..masked..after
			end
			
			-- Update punishment data
			punish.fine = math.max(punish.fine, item.fine)
			punish.mute = math.max(punish.mute, item.mute)
			punish.warn = punish.warn or item.warn
			punish.hide = punish.hide or item.hide
		end
	end
	
	if(not found) then
		return msg, false
	end
	
	-- Censored words have been found
	punish.fine = math.max(punish.fine, Settings.censor_fine)
	punish.mute = math.max(punish.mute, Settings.censor_mute)
	punish.warn = punish.warn or Settings.censor_warn
	punish.hide = punish.hide or Settings.censor_hide
	
	if(punish.hide) then
		msg = false
	end
	
	return msg, punish
end

function CsPunish(player, punishment)
	local msg = false
	if(punishment.fine > 0) then
		player.accountData:add('cash', -punishment.fine)
		outputMsg(player, Styles.red, "Do not swear %s! %s has been taken from your cash.", player:getName(true), formatMoney(punishment.fine))
		msg = true
	end
	
	if(punishment.mute > 0) then
		if(player:mute(punishment.mute, 'Censor')) then
			outputMsg(g_Root, Styles.red, "%s has been muted by Censor (%u seconds)!", player:getName(true), punishment.mute)
			msg = true
		end
	end
	
	if(punishment.warn) then
		if(not warnPlayer(player, Player.getConsole(), 'Censor')) then
			outputMsg(player, Styles.red, "You have been warned by Censor!")
		end
		msg = true
	end
	
	if(punishment.hide and not msg) then
		outputMsg(player, Styles.red, "Your message contains disallowed content!")
	end
end

local function CsLoadWords()
	local node = xmlLoadFile('conf/censor.xml')
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		local word = xmlNodeGetValue(subnode)
		assert(word:len() > 0)
		
		local item = {}
		item.fine = touint(attr.price, 0)
		item.mute = touint(attr.mute, 0)
		item.hide = tobool(attr.hide)
		item.warn = tobool(attr.warn)
		g_ForbWords[word] = item
	end
	
	xmlUnloadFile(node)
	return true
end

local function CsInit ()
	CsLoadWords()
end

addInitFunc(CsInit)
