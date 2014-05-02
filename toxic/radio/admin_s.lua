--namespace('Radio')

local g_Right = AccessRight('RadioChannels')

local function loadChannels()
	local channels = Cache.get('Radio.Channels')
	if(channels) then return channels end
	
	channels = {}
	local node, i = xmlLoadFile('conf/radio.xml'), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, 'channel', i)
			if(not subnode) then break end
			i = i + 1
			
			local ch = {}
			ch.name = xmlNodeGetAttribute(subnode, 'name')
			ch.img = xmlNodeGetAttribute(subnode, 'img')
			ch.url = xmlNodeGetValue(subnode)
			assert(ch.name and ch.url)
			
			table.insert(channels, ch)
		end
		
		xmlUnloadFile(node)
	else
		Debug.warn('Failed to load radio channnels list')
	end
	
	table.sort(channels, function(ch1, ch2) return ch1.name:lower() < ch2.name:lower() end)
	Cache.set('Radio.Channels', channels, 300)
	
	return channels
end

local function saveChannels(channels)
	local node = xmlCreateFile('conf/radio.xml', 'channels')
	if(not node) then return false end
	
	table.sort(channels, function(ch1, ch2) return ch1.name:lower() < ch2.name:lower() end)
	Cache.set('Radio.Channels', channels, 300)
	
	for i, ch in ipairs(channels) do
		local subnode = xmlCreateChild(node, 'channel')
		xmlNodeSetValue(subnode, ch.url)
		xmlNodeSetAttribute(subnode, 'name', ch.name)
		if(ch.img) then
			xmlNodeSetAttribute(subnode, 'img', ch.img)
		end
	end
	
	xmlSaveFile(node)
	xmlUnloadFile(node)
end

local function handleIndexPage(request, response)
	response:beginPage(g_ResName..' - Radio Channels')
	local channels = loadChannels()
	response:writeTpl('radio/tpl/index.html', {channels = channels})
	response:endPage()
end

local function getUniqueFilename(path)
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
	while(fileExists(dir..filename)) do
		filename = base..'_'..i..ext
		i = i + 1
	end
	
	return dir..filename, filename
end

local function handleEditPage(request, response)
	local ch = false
	local edit = request.params.id and true
	local channels = loadChannels()
	for i, ch2 in ipairs(channels) do
		if(ch2.url == request.params.id) then
			ch = ch2
			break
		end
	end
	if(edit and not ch or request.params.cancel) then response:redirect('/radio/admin') return end
	
	if(not ch) then
		-- New channel
		ch = {name = '', url = ''}
	end
	
	local err
	if(request.params.save) then
		local oldCh = table.copy(ch)
		ch.name = request.params.name or ''
		ch.url = request.params.url or ''
		ch.img = request.params.img
		if(ch.img == '') then ch.img = false end
		
		local uploadedImg = {name = request.params.imgUpload, content = request.params.imgUpload_content}
		if(not uploadedImg.name or not uploadedImg.content) then
			uploadedImg = false
		else
			--Debug.info('before decode '..uploadedImg.content:len())
			--Debug.info(uploadedImg.content)
			uploadedImg.content = base64Decode(uploadedImg.content)
			--uploadedImg.content = fromJSON(uploadedImg.content)
			--Debug.info('after decode '..uploadedImg.content:len())
			uploadedImg.ext = uploadedImg.name:match('(%.[^%.]+)$')
		end
		
		local allowedExtensions = {'.jpg', '.png', '.gif'}
		
		if(ch.name == '') then
			err = 'Name cannot be empty!'
		elseif(ch.url == '') then
			err = 'URL cannot be empty!'
		elseif(uploadedImg and not table.find(allowedExtensions, uploadedImg.ext)) then
			err = 'Invalid image file extension!'
		else
			if(not edit) then
				table.insert(channels, ch)
			end
			
			local meta = MetaFile(':txmedia/meta.xml')
			local metaChanged = false
			
			if(oldCh.img and (oldCh.img ~= ch.img or uploadedImg)) then
				-- Remove old image
				fileDelete(':txmedia/'..oldCh.img)
				meta:removeFile(oldCh.img)
				metaChanged = true
			end
			
			if(uploadedImg) then
				local path, filename = getUniqueFilename(':txmedia/'..uploadedImg.name)
				fileSetContents(path, uploadedImg.content)
				ch.img = filename
				
				meta:addClientFile(filename)
				metaChanged = true
				Debug.info('uploaded file '..uploadedImg.name..' size '..uploadedImg.content:len()..' saved in '..path)
			end
			
			if(metaChanged) then
				meta:save()
			end
			meta:close()
			
			saveChannels(channels)
			response:redirect('/radio/admin')
			return
		end
	end
	
	local title = g_ResName..' - '..(edit and 'Edit' or 'Create')..' Radio Channel'
	response:beginPage(title, '<script src="/toxic/http/fileUpload.js"></script>')
	response:writeTpl('radio/tpl/edit.html', {edit = edit, err = err, ch = ch})
	response:endPage()
end

local function handleDeletePage(request, response)
	local found = false
	local channels = loadChannels()
	for i, ch2 in ipairs(channels) do
		if(ch2.url == request.params.id) then
			found = true
			table.remove(channels, i)
			break
		end
	end
	if(found) then
		saveChannels(channels)
	end
	response:redirect('/radio/admin')
end

addInitFunc(function()
	Http.addRoute('/radio/admin', handleIndexPage, g_Right)
	Http.addRoute('/radio/edit', handleEditPage, g_Right)
	Http.addRoute('/radio/delete', handleDeletePage, g_Right)
end)
