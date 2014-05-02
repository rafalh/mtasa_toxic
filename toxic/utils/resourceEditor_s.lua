ResourceEditor = Class('ResourceEditor')

function ResourceEditor.__mt.__index:init(name)
	self.res = Resource(name)
	self.meta = MetaFile(':'..name..'/meta.xml')
	self.metaChanged = false
end

function ResourceEditor.__mt.__index:destroy()
	self:save()
	self.meta:close()
end

function ResourceEditor.__mt.__index:save()
	if(self.metaChanged) then
		self.meta:save()
		self.metaChanged = false
	end
end

function ResourceEditor.__mt.__index:getUniqueFilename(path)
	local dir, filename = path:match('^(.*[/\\])(.+)$')
	if(not dir) then
		dir = ''
		filename = path
	end
	
	local base, ext = filename:match('^(.+)(%.[^%.]+)$')
	if(not base) then
		base = filename
		ext = ''
	end
	
	local i = 2
	local resDir = ':'..self.res:getName()..'/'
	while(fileExists(resDir..dir..filename)) do
		filename = base..'_'..i..ext
		i = i + 1
	end
	
	return dir..filename
end

function ResourceEditor.__mt.__index:addFile(filename, content, type, attr)
	local path = ':'..self.res:getName()..'/'..filename
	if(fileExists(path)) then return false end
	
	-- Save file on disk
	if(not fileSetContents(path, content)) then return false end
	
	-- Add file to resource meta
	if(not self.meta:addFile(filename, type, attr)) then
		fileDelete(path)
		return false
	end
	
	-- Success
	self.metaChanged = true
	return true
end

function ResourceEditor.__mt.__index:deleteFile(filename)
	local path = ':'..self.res:getName()..'/'..filename
	if(not fileExists(path)) then return false end
	
	-- Find file in meta and remember some info to be used later
	local type, attr = self.meta:getFileInfo(filename)
	if(not type) then return false end
	
	-- Remove file entry from meta
	if(not self.meta:removeFile(filename)) then return false end
	
	-- Delete file
	if(not fileDelete(path)) then
		-- Failed - undo meta changes
		self.meta:addFile(filename, type, attr)
		return false
	end
	
	-- Success
	self.metaChanged = true
	return true
end
