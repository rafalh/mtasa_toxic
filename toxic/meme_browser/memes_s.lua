namespace('MemeBrowser')

local g_Services = {}

g_Services.demotywatory = {
	getImages = function(self, callback, page, ...)
		local url
		if (page) then
			url = 'http://demotywatory.pl/page/'..page
		else
			url = 'http://demotywatory.pl/losuj'
		end
		
		local redirectCounter = 0
		local fetchRemoteCallback
		fetchRemoteCallback = function(data, errno, ...)
			if (errno ~= 0) then
				Debug.err('Failed to download demotywatory images')
				callback(false, page, ...)
				return
			end
			
			if (data:match('302%s*%-%s*Found') and redirectCounter < 3) then
				local url = data:match('<a href="([^"]+)">')
				fetchRemote(url, fetchRemoteCallback, '', false, ...)
				redirectCounter = redirectCounter + 1
				return
			elseif (data:len() < 200) then
				Debug.warn('Something went wrong '..data)
			end
			
			local imgList = {}
			local pattern = '<img%s+src="([^"]+)"%s+alt="([^"]+)"%s+class="demot".-/>'
			for url, title in data:gmatch(pattern) do
				local title1, title2 = title:match('^(.-)%s*&ndash;%s*(.-)$')
				if (title1 and title2) then
					if (title2:len() > 0) then
						title = title1..' - '..title2
					else
						title = title1
					end
				end
				table.insert(imgList, {url, title})
			end
			callback(imgList, page, ...)
		end
		
		fetchRemote(url, fetchRemoteCallback, '', false, ...)
	end,
	reqMap = {},
	state = 'idle',
}

g_Services.kwejk = {
	getImages = function(self, callback, page, ...)
		local url
		if (page) then
			local page2 = 10 - (page - 1)
			url = 'http://kwejk.pl/top/week/'..page2
		else
			url = 'http://kwejk.pl/losuj?utm_source=glowna&utm_medium=button&utm_campaign=losuj'
		end
		
		local redirectCounter = 0
		local fetchRemoteCallback
		fetchRemoteCallback = function(data, errno, ...)
			if (errno ~= 0) then
				Debug.err('Failed to download kwejk images')
				callback(false, page, ...)
				return
			end
			
			local redirectUrl = data:match('You are being <a href="([^"]+)">redirected</a>')
			if (redirectUrl and redirectCounter < 3) then
				fetchRemote(redirectUrl, fetchRemoteCallback, '', false, ...)
				redirectCounter = redirectCounter + 1
				return
			elseif (data:len() < 1000) then
				Debug.warn('Something went wrong '..data)
			end
			
			local imgList = {}
			local pattern = '<a href="[^"]+" class="mOUrl" target="_self"><img alt="[^"]+" src="([^"]+)" title="([^"]+)" /></a>'
			for url, title in data:gmatch(pattern) do
				table.insert(imgList, {url, title})
			end
			callback(imgList, page, ...)
		end
		fetchRemote(url, fetchRemoteCallback, '', false, ...)
	end,
	reqMap = {},
	state = 'idle',
}

local function sendImageToClients(page, index, title, data, serviceId)
	local service = g_Services[serviceId]
	for client, _ in pairs(service.reqMap) do
		RPC('MemeBrowser.addImage', page, index, title, data):setClient(client):exec()
	end
end

local function downloadImages(imgList, page, serviceId)
	Debug.info('Download '..serviceId..' images - '..#imgList)
	for i, info in ipairs(imgList) do
		local imgData = FileCache.get(info[1])
		if (imgData) then
			sendImageToClients(page, i, info[2], imgData, serviceId)
		else
			fetchRemote(info[1], function(data, errno)
				if (errno ~= 0) then
					Debug.err('Failed to download image')
					return
				end
				
				FileCache.set(info[1], data, 10*60)
				sendImageToClients(page, i, info[2], data, serviceId)
			end)
		end
	end
end

local function imgListCallback(imgList, page, serviceId)
	if (page) then
		Cache.set('MemeBrowser.ImgList.'..serviceId..'.'..page, imgList, 15*60)
	end
	local service = g_Services[serviceId]
	service.state = 'idle' -- FIXME: nie sciagaj obrazkow jak wlasnie sa sciagane
	downloadImages(imgList, page, serviceId)
end

function requestImages(serviceId, page)
	local service = g_Services[serviceId]
	if (not service) then return end
	
	service.reqMap[client] = true
	if (service.state == 'idle') then
		local imgList = page and Cache.get('MemeBrowser.ImgList.'..serviceId..'.'..page)
		if (imgList) then
			downloadImages(imgList, page, serviceId)
		else
			service.state = 'listDownload'
			service:getImages(imgListCallback, page, serviceId)
		end
	end
end
RPC.allow('MemeBrowser.requestImages')

local function onPlayerQuit()
	for id, service in pairs(g_Services) do
		service.reqMap[source] = nil
	end
end

addInitFunc(function()
	addEventHandler('onPlayerQuit', root, onPlayerQuit)
end)
