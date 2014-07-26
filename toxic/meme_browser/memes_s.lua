namespace('MemeBrowser')

local g_Services = {}

g_Services.demotywatory = {
	getImages = function(callback, ...)
		fetchRemote('http://demotywatory.pl/', function(data, errno, ...)
			if (errno ~= 0) then
				Debug.err('Failed to download demotywatory images')
				callback(false, ...)
				return
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
			callback(imgList, ...)
		end, '', false, ...)
	end,
	reqMap = {},
	state = 'idle',
}

g_Services.kwejk = {
	getImages = function(callback, ...)
		fetchRemote('http://kwejk.pl/top/week', function(data, errno, ...)
			if (errno ~= 0) then
				Debug.err('Failed to download kwejk images')
				callback(false, ...)
				return
			end
			
			local imgList = {}
			local pattern = '<a href="[^"]+" class="mOUrl" target="_self"><img alt="[^"]+" src="([^"]+)" title="([^"]+)" /></a>'
			for url, title in data:gmatch(pattern) do
				table.insert(imgList, {url, title})
			end
			callback(imgList, ...)
		end, '', false, ...)
	end,
	reqMap = {},
	state = 'idle',
}

local function downloadImages(imgList, serviceId)
	Debug.info('Download '..serviceId..' images - '..#imgList)
	local service = g_Services[serviceId]
	for i, info in ipairs(imgList) do
		fetchRemote(info[1], function(data, errno)
			if (errno ~= 0) then
				Debug.err('Failed to download image')
				return
			end
			
			for client, _ in pairs(service.reqMap) do
				RPC('MemeBrowser.addImage', i, info[2], data):setClient(client):exec()
			end
		end)
	end
	Debug.info('TODO')
end

local function imgListCallback(imgList, serviceId)
	Cache.set('MemeBrowser.ImgList.'..serviceId, imgList, 3600)
	downloadImages(imgList, serviceId)
end

function requestImages(serviceId)
	local service = g_Services[serviceId]
	if (not service) then return end
	
	service.reqMap[client] = true
	if (service.state == 'idle') then
		local imgList = Cache.get('MemeBrowser.ImgList.'..serviceId)
		if (imgList) then
			downloadImages(imgList, serviceId)
		else
			service.getImages(imgListCallback, serviceId)
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
