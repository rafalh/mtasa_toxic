function string.trim(str)
	str = str:gsub('^%s+', '')
	str = str:gsub('%s+$', '')
	return str
end

function string.upperCaseWords(str)
	return str:gsub('^(%w)', function(letter)
		return letter:upper()
	end):gsub('(%s)(%w)', function(space, letter)
		return space..letter:upper()
	end)
end

function string.beginsWith(str, prefix)
	return (str:sub(1, prefix:len()) == prefix)
end

function string.wordWrapSplitIter(str, maxLen)
	local i = 1
	return function ()
		local part = str:sub(i, i + maxLen)
		if part == '' then
			return nil
		end

		-- check if part length is less then maxLen+1
		if part:len() <= maxLen then
			i = i + part:len()
			return part
		end

		-- find last space
		local spaceRevPos = part:reverse():find('%s')
		local spacePos = spaceRevPos and (part:len() - spaceRevPos + 1)
		if not spacePos or spacePos < maxLen/2 then
			i = i + maxLen
			return part:sub(1, maxLen)
		end

		i = i + spacePos
		return part:sub(1, spacePos - 1)
	end
end

function string.escapePattern(str)
	return str:gsub('[%(%)%.%%%+%-%*%?%[%]%^%$]', '%%%0')
end

-- Obsulate:
trimStr = string.trim
upperCaseWords = string.upperCaseWords

#if(TEST) then
addInitFunc(function()
	Test.register('utils.string', function()
		Test.checkEq(toJSON(table.fromIter(string.wordWrapSplitIter('1234567890', 4))), toJSON({'1234', '5678', '90'}))
		Test.checkEq(toJSON(table.fromIter(string.wordWrapSplitIter('1 2 3 4 5', 4))), toJSON({'1 2', '3 4', '5'}))
		Test.checkEq(toJSON(table.fromIter(string.wordWrapSplitIter('1 2 33333', 5))), toJSON({'1 2', '33333'}))
	end)
end)
#end

