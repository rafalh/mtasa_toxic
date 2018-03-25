namespace('Radio')

local g_Right = AccessRight('RadioChannels')

local function handleIndexPage(request, response)
	response:beginPage(g_ResName..' - Radio Channels')
	local channels = getChannels()
	response:writeTpl('radio/tpl/index.html', {channels = channels})
	response:endPage()
end

local function handleEditPage(request, response)
	local ch = false
	local edit = request.params.id and true
	local channels = getChannels()
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
		local newCh = {}
		newCh.name = request.params.name or ''
		newCh.url = request.params.url or ''
		newCh.img = request.params.img
		if(newCh.img == '') then newCh.img = false end
		
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
			newCh.img = false
		end
		
		local allowedExtensions = {'.jpg', '.png', '.gif'}
		
		if(newCh.name == '') then
			err = 'Name cannot be empty!'
		elseif(newCh.url == '') then
			err = 'URL cannot be empty!'
		elseif(uploadedImg and not table.find(allowedExtensions, uploadedImg.ext)) then
			err = 'Invalid image file extension!'
		else
			local mediaRes = ResourceEditor('txmedia')
			
			if(oldCh.img and (oldCh.img ~= newCh.img or uploadedImg)) then
				-- Remove old image
				if(not mediaRes:deleteFile(oldCh.img)) then
					--newCh.img = oldCh.img
					Debug.warn('mediaRes:deleteFile '..oldCh.img..' failed')
				end
			end
			
			if(uploadedImg) then
				local filename = mediaRes:getUniqueFilename(uploadedImg.name)
				if(mediaRes:addFile(filename, uploadedImg.content)) then
					newCh.img = filename
				else
					Debug.warn('mediaRes:addFile '..filename..' failed')
				end
				--Debug.info('uploaded file '..uploadedImg.name..' size '..uploadedImg.content:len()..' saved in '..path)
			end
			
			mediaRes:destroy()
			
			if(not edit) then
				table.insert(channels, newCh)
			else
				table.set(ch, newCh)
			end
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
	local channels = getChannels()
	for i, ch in ipairs(channels) do
		if(ch.url == request.params.id) then
			found = true
			table.remove(channels, i)
			if(ch.img) then
				local mediaRes = ResourceEditor('txmedia')
				if(not mediaRes:deleteFile(ch.img)) then
					Debug.warn('mediaRes:deleteFile '..ch.img..' failed')
				end
				mediaRes:destroy()
			end
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
