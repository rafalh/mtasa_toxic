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

-- Obsulate:
trimStr = string.trim
upperCaseWords = string.upperCaseWords
