function fileGetContents(path)
	local file = fileOpen(path, true)
	if (not file) then
		outputDebugString("Failed to open "..path, 2)
		return false
	end
	
	local size = fileGetSize(file)
	local buf = size > 0 and fileRead(file, size) or ""
	fileClose(file)
	
	return buf
end

function fileSetContents(path, buf)
	local file = fileCreate (path)
	if(not file) then return false end
	
	fileWrite(file, buf)
	fileClose(file)
end

function fileGetMd5(path)
	local buf = fileGetContents(path)
	if(not buf) then
		return false
	end
	
	return md5(buf)
end
