local g_ForbWords = {}

function table.removeMultiple(tbl, pos, count)
	--assert(pos + count <= #tbl + 1)
	for i = 1, count do
		table.remove(tbl, pos)
	end
end

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
				local repl2 = ('*'):rep(j - i + 1)
				if(not repl) then
					-- Change word to *****
					repl = repl2
				end
				
				-- FIXME: offsets are invalid if #repl ~= #repl2
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
	if(not Settings.censor_nicknames) then return false end
	--outputDebugString('CsCheckNickname '..name, 3)
	
	local plainName = name:lower():gsub('#%x%x%x%x%x%x', '')
	for i, item in ipairs(g_ForbWords) do
		if(plainName:find(item.pattern)) then
			--outputDebugString('Detected banned nickname: '..plainName, 3)
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
	local node = xmlLoadFile('conf/censor.xml')
	if(not node) then return false end
	
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
	
	xmlUnloadFile(node)
	return true
end

local function CsInit()
	-- Note: called before players are created
	CsLoadWords()
end

addPreInitFunc(CsInit)

#local TEST = false
#if(TEST) then
	local function areTablesEqual(tbl1, tbl2)
		if(type(tbl1) ~= 'table' or type(tbl2) ~= 'table') then return false end
		
		for i, v in pairs(tbl1) do
			if(type(tbl2[i]) == 'table' and type(v) == 'table') then
				if(not areTablesEqual(tbl2[i], v)) then return false end
			elseif(tbl2[i] ~= v) then
				return false
			end
		end
		
		for i, v in pairs(tbl2) do
			if(type(tbl1[i]) == 'table' and type(v) == 'table') then
				if(not areTablesEqual(tbl1[i], v)) then return false end
			elseif(tbl1[i] ~= v) then
				return false
			end
		end
		
		return true
	end

	local function TestEq(result, validResult)
		if(result == validResult) then return end
		local trace = DbgTraceBack(-1, 1, 1)
		outputDebugString('Test failed: expected '..tostring(validResult)..', got '..tostring(result)..' in '..trace[1], 2)
	end

	local function TestTblEq(tbl, validTbl)
		assert(type(tbl) == 'table' and type(validTbl) == 'table')
		if(areTablesEqual(tbl, validTbl)) then return end
		local trace = DbgTraceBack(-1, 1, 1)
		outputDebugString('Test failed: expected '..table.dump(validTbl)..', got '..table.dump(tbl)..' in '..trace[1], 2)
	end

	local prof = DbgPerf(5)
	
	TestTblEq({CsPreprocessStr('AbC')}, {'abc', {1, 2, 3}})
	TestTblEq({CsPreprocessStr('abc d')}, {'abc d', {1, 2, 3, 4, 5}})
	TestTblEq({CsPreprocessStr('a bcd')}, {'a bcd', {1, 2, 3, 4, 5}})
	TestTblEq({CsPreprocessStr('a b')}, {'ab', {1, 3}})
	TestTblEq({CsPreprocessStr('abc d e')}, {'abc de', {1, 2, 3, 4, 5, 7}})
	TestTblEq({CsPreprocessStr('a b cde')}, {'ab cde', {1, 3, 4, 5, 6, 7}})
	TestTblEq({CsPreprocessStr('abc d e fg')}, {'abc de fg', {1, 2, 3, 4, 5, 7, 8, 9, 10}})
	TestTblEq({CsPreprocessStr('a b c')}, {'abc', {1, 3, 5}})
	
	TestTblEq({CsPreprocessStr('#000000')}, {'', {}})
	TestTblEq({CsPreprocessStr('#000000#FFFFFF')}, {'', {}})
	TestTblEq({CsPreprocessStr('ab#000000cd')}, {'abcd', {1, 2, 10, 11}})
	
	TestTblEq({CsPreprocessStr('a b#000000 c d')}, {'abcd', {1, 3, 12, 14}})
	
	prof:cp('CsPreprocessStr test')
#end
