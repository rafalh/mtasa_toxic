MapList = {}
MapList.__mt = {__index = MapList}

function MapList:get(i)
	local mapRes = self.resList[i]
	return mapRes and Map.create(mapRes)
end

function MapList:getCount()
	return #self.resList
end

function MapList:iterator(i)
	local map = self:get(i)
	if(not map) then return end
	i = i + 1
	return i, map
end

function MapList:ipairs()
	return MapList.iterator, self, 1
end

function MapList:remove(i)
	local mapRes = table.remove(self.resList, i)
	return mapRes and Map.create(mapRes)
end

function MapList.create(mapResList)
	local self = setmetatable({}, MapList.__mt)
	
	self.resList = mapResList
	
	return self
end
