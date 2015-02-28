local g_ForbWords = {}

function CsPreprocessStr(str)
	local offsets = {}
	
	for i = 1, #str do
		table.insert(offsets, i)
	end
	
	str = str:lower()
	
	local tmp = 0
	str = str:gsub('()#%x%x%x%x%x%x', function(idx)
		table.removeMultiple(offsets, idx - tmp, 7)
		tmp = tmp + 7
		return ''
	end)
	
	tmp = 0
	local i = 0
	str = str:gsub('()(%W*)(%w+)', function(idx, rest, word)
		if(word:len() ~= 1) then
			i = 0
		elseif(i >= 1) then
			if(#rest > 0) then
				table.removeMultiple(offsets, idx - tmp, #rest)
				tmp = tmp + #rest
			end
			return word
		else
			i = i + 1
		end
	end)
	
	return str, offsets
end

function CsProcessMsg(msg)
	if(not Settings.censor) then
		return msg, false
	end
	
	local prof = DbgPerf(5)
	local buf, offsets = CsPreprocessStr(msg)
	
	local punish = {fine = 0, mute = 0, warn = false, hide = false}
	local replaceWords = Settings.censor_replace
	local found = false
	
	for i, item in ipairs(g_ForbWords) do
		for i, j in buf:gmatch('()'..item.pattern..'()') do
			-- Bad word has been found
			found = true
			
			if(replaceWords) then
				local repl = item.repl
				local repl2 = ('*'):rep(j - i)
				if(not repl) then
					-- Change word to *****
					repl = repl2
				end
				
				if(#repl ~= #repl2) then
					for k = j, #offsets do
						offsets[k] = offsets[k] + #repl - #repl2
					end
				end
				local before = msg:sub(1, offsets[i] - 1)
				local after = msg:sub(offsets[j - 1] + 1)
				msg = before..repl..after
				buf = buf:sub(1, i - 1)..repl2..buf:sub(j)
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
	
	prof:cp('CsProcessMsg')
	
	return msg, punish
end

function CsCheckNickname(name)
	if(not Settings.censor or not Settings.censor_nicknames) then return false end
	--Debug.info('CsCheckNickname '..name)
	
	local plainName = name:lower():gsub('#%x%x%x%x%x%x', '')
	for i, item in ipairs(g_ForbWords) do
		if(plainName:find(item.pattern)) then
			--Debug.info('Detected banned nickname: '..plainName)
			return true
		end
	end
	
	return false
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
	-- Open censor configuration file
	local node = xmlLoadFile('conf/censor.xml')
	if(not node) then return false end
	
	-- Load all words
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local attr = xmlNodeGetAttributes(subnode)
		local word = xmlNodeGetValue(subnode)
		assert(word:len() > 0)
		
		local item = {}
		item.pattern = word:lower():gsub('%a', '%1+')
		item.fine = touint(attr.price, 0)
		item.mute = touint(attr.mute, 0)
		item.hide = tobool(attr.hide)
		item.warn = tobool(attr.warn)
		item.repl = attr.repl
		table.insert(g_ForbWords, item)
	end
	
	-- Unload file
	xmlUnloadFile(node)
	
	-- Sort patterns from longest to shortest to fix problems with one pattern containing another
	table.sort(g_ForbWords, function(a, b)
		return a.pattern:len() > b.pattern:len()
	end)
	assert(g_ForbWords[1].pattern:len() >= g_ForbWords[#g_ForbWords-1].pattern:len())
	
	return true
end

local function CsInit()
	-- Note: called before players are created
	CsLoadWords()
end

addInitFunc(CsInit, -200)

#if(TEST) then
	Test.register('censor', function()
		Test.checkTblEq({CsPreprocessStr('AbC')}, {'abc', {1, 2, 3}})
		Test.checkTblEq({CsPreprocessStr('abc d')}, {'abc d', {1, 2, 3, 4, 5}})
		Test.checkTblEq({CsPreprocessStr('a bcd')}, {'a bcd', {1, 2, 3, 4, 5}})
		Test.checkTblEq({CsPreprocessStr('a b')}, {'ab', {1, 3}})
		Test.checkTblEq({CsPreprocessStr('abc d e')}, {'abc de', {1, 2, 3, 4, 5, 7}})
		Test.checkTblEq({CsPreprocessStr('a b cde')}, {'ab cde', {1, 3, 4, 5, 6, 7}})
		Test.checkTblEq({CsPreprocessStr('abc d e fg')}, {'abc de fg', {1, 2, 3, 4, 5, 7, 8, 9, 10}})
		Test.checkTblEq({CsPreprocessStr('a b c')}, {'abc', {1, 3, 5}})
		
		Test.checkTblEq({CsPreprocessStr('#000000')}, {'', {}})
		Test.checkTblEq({CsPreprocessStr('#000000#FFFFFF')}, {'', {}})
		Test.checkTblEq({CsPreprocessStr('ab#000000cd')}, {'abcd', {1, 2, 10, 11}})
		
		Test.checkTblEq({CsPreprocessStr('a b#000000 c d')}, {'abcd', {1, 3, 12, 14}})
	end)
#end
