--namespace('Radio')

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
		ch.name = request.params.name or ''
		ch.url = request.params.url or ''
		ch.img = request.params.img or ''
		
		if(ch.name == '') then
			err = 'Name cannot be empty!'
		elseif(ch.url == '') then
			err = 'URL cannot be empty!'
		else
			if(not edit) then
				table.insert(channels, ch)
			end
			saveChannels(channels)
			response:redirect('/radio/admin')
			return
		end
	end
	
	response:beginPage(g_ResName..' - '..(edit and 'Edit' or 'Create')..' Radio Channel')
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
	Http.addRoute('/radio/admin', handleIndexPage)
	Http.addRoute('/radio/edit', handleEditPage)
	Http.addRoute('/radio/delete', handleDeletePage)
end)
