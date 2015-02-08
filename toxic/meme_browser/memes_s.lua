namespace('MemeBrowser')

local function htmlDecode(str)
	local tbl = {
		['lt'] = '<',
		['gt'] = '>',
		['quot'] = '"',
		['apos'] = '\'',
		['nbsp'] = ' ',
		['amp'] = '&',
		['oacute'] = 'ó',
	}
	return str:gsub('&([#%w]+);', function(s)
		if (s:sub(1, 1) == '#') then
			return string.char(s:sub(2))
		else
			return tbl[s]
		end
	end)
end

local g_Services = {}

g_Services.demotywatory = {
	getImageList = function(self, callback, page, ...)
		local url, cacheResponse
		if (page) then
			url = 'http://demotywatory.pl/page/'..page
			cacheResponse = true
		else
			url = 'http://demotywatory.pl/losuj'
		end
		
		DownloadMgr.get(url, cacheResponse, function(data, ...)
			if (not data) then
				Debug.err('Failed to download demotywatory images')
				callback(false, page, ...)
			elseif (data:len() < 200) then
				Debug.warn('Something went wrong '..data)
			else
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
					local imgInfo = {url, htmlDecode(title)}
					table.insert(imgList, imgInfo)
				end
				callback(imgList, page, ...)
			end
		end, ...)
	end,
}

g_Services.kwejk = {
	getImageList = function(self, callback, page, ...)
		local url, cacheResponse
		if (page) then
			if (page == 1 or not self.pageNum) then
				url = 'http://kwejk.pl/' -- FIXME: page
			else
				url = 'http://kwejk.pl/strona/'..self.pageNum - (page - 1)
			end
			cacheResponse = true
		else
			url = 'http://kwejk.pl/losuj'
		end
		
		DownloadMgr.get(url, cacheResponse, function(data, ...)
			if (not data) then
				Debug.err('Failed to download kwejk images')
				callback(false, page, ...)
			elseif (data:len() < 1000) then
				Debug.warn('Something went wrong '..data)
			else
				local imgList = {}
				--local pattern = '<a data-track="true" data-track-category="[^"]+"+ data-track-action="[^"]+" data-track-label="[^"]+" +href="[^"]+">%s+<img src="([^"]+)" +alt="([^"]+)" />%s+</a>'
				local pattern = 'data%-track%-label="[^"]+"%s+href="[^"]+">%s+<img src="([^"]+)" +alt="([^"]+)" />%s+</a>'
				for url, title in data:gmatch(pattern) do
					local imgInfo = {url, htmlDecode(title)}
					table.insert(imgList, imgInfo)
				end
				callback(imgList, page, ...)
				
				local pagesTotal = data:match('pagesTotal: (%d+)')
				if (pagesTotal) then
					self.pageNum = pagesTotal
				end
			end
		end, ...)
	end,
}

local function downloadImages(imgList, page, serviceId, playerEl)
	Debug.info('Download '..serviceId..' images - '..#imgList)
	for i, imgInfo in ipairs(imgList) do
		DownloadMgr.get(imgInfo[1], true, function(data)
			if (isElement(playerEl)) then
				RPC('MemeBrowser.addImage', page, i, imgInfo[2], data):setClient(playerEl):exec()
			end
		end)
	end
end

function requestImages(serviceId, page)
	local service = g_Services[serviceId]
	if (not service) then return end
	
	service:getImageList(downloadImages, page, serviceId, client)
end
RPC.allow('MemeBrowser.requestImages')

local function onPlayerQuit()
	for id, service in pairs(g_Services) do
		-- TODO
	end
end

addInitFunc(function()
	addEventHandler('onPlayerQuit', root, onPlayerQuit)
end)
