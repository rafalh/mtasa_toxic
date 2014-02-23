local StringList = Class('StringList')

function StringList.__mt.__index:init()
	self.strList = {}
	self.typeList = {}
	self.providers = {}
	self.loadedFiles = {}
end

function StringList.__mt.__index:loadFromFile(path)
	if(self.loadedFiles[path]) then return end
	
	local buf = fileGetContents(path)
	if(not buf) then return false end
	
	buf = buf:gsub('\r\n', '\n')
	local tbl = split(buf, '\n')
	for i, v in ipairs(tbl) do
		local strType = v:sub(1, 1)
		local str = v:sub(3)
		
		if(strType == 's' or strType == 'c' or strType == '*') then
			table.insert(self.strList, str)
			table.insert(self.typeList, strType)
		else
			Debug.warn('Invalid line '..i..' in MUI string list')
			break
		end
	end
	
	self.loadedFiles[path] = true
	return true
end

function StringList.__mt.__index:registerProvider(provider)
	table.insert(self.providers, provider)
end

function StringList.__mt.__index:count()
	local count = #self.strList
	for i, prov in ipairs(self.providers) do
		count = count + prov:getStringCount()
	end
	return count
end

function StringList.__mt.__index:iterator(i)
	i = i - self.curProvOffset
	local prov = self.providers[self.curProvIdx]
	local str, strType
	if(prov) then
		str, strType = prov:getString(i)
	else
		str = self.strList[i]
		strType = self.typeList[i]
	end
	
	while(not str and self.curProvIdx < #self.providers) do
		self.curProvIdx = self.curProvIdx + 1
		self.curProvOffset = self.curProvOffset + i - 1
		i = 1
		prov = self.providers[self.curProvIdx]
		str, strType = prov:getString(i)
	end
	
	if(not str) then return end
	
	i = i + 1
	return i + self.curProvOffset, str, strType
end

function StringList.__mt.__index:ipairs()
	self.curProvIdx = 0
	self.curProvOffset = 0
	return self.iterator, self, 1
end

MuiStringList = StringList()
