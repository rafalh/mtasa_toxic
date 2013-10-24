MapList = Class('MapList')

function MapList.__mt.__index:get(i)
	local mapRes = self.resList[i]
	return mapRes and Map(mapRes)
end

function MapList.__mt.__index:getCount()
	return #self.resList
end

function MapList.__mt.__index:iterator(i)
	local map = self:get(i)
	if(not map) then return end
	i = i + 1
	return i, map
end

function MapList.__mt.__index:ipairs()
	return self.iterator, self, 1
end

function MapList.__mt.__index:remove(i)
	local mapRes = table.remove(self.resList, i)
	return mapRes and Map(mapRes)
end

function MapList.__mt.__index:init(mapResList)
	assert(type(mapResList) == 'table')
	self.resList = mapResList
end
