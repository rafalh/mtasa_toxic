namespace('DownloadMgr')

local g_Requests = {}
local g_CurlToUrl = {}
local g_Buffers = {}

local function finishRequest(req, url, data)
	if (req.cache) then
		if (data:len() >= 2048) then
			FileCache.set('DownloadMgr.'..url, data, 10*60)
		else
			Cache.set('DownloadMgr.'..url, data, 10*60)
		end
	end

	for i, callback in ipairs(req.callbacks) do
		callback[1](data, unpack(callback[2]))
	end
end

local function failRequest(req)
	for i, callback in ipairs(req.callbacks) do
		callback[1](false, unpack(callback[2]))
	end
end

local function fetchCallback(data, errno, url)
	local req = g_Requests[url]
	g_Requests[url] = nil

	if errno ~= 0 then
		Debug.err('Download failed (errno '..errno..')')
		failRequest(req)
	else
		finishRequest(req, url, data)
	end
end

function get(url, cacheResponse, callback, ...)
	--Debug.info('DownloadMgr.get '..url)

	local data = Cache.get('DownloadMgr.'..url)
	if (not data) then
		data = FileCache.get('DownloadMgr.'..url)
	end
	
	if (data) then
		callback(data, ...)
	else
		local fetch = false
		local req = g_Requests[url]
		if (not req) then
			req = {callbacks = {}}
			fetch = true
		end
		
		table.insert(req.callbacks, {callback, {...}})
		req.cache = req.cache or cacheResponse
		
		if (fetch) then
			local ret
			if curlInit then
				local curl = curlInit(url)
				g_CurlToUrl[curl] = url
				curlSetopt(curl, 'CURLOPT_FOLLOWLOCATION', true)
				ret = curlPerform(curl)
			else
				ret = fetchRemote(url, fetchCallback, '', false, url)
			end

			if (ret) then
				g_Requests[url] = req
			else
				callback(false, ...)
			end
		end
	end
end

local function onCurlData(curl, data)
	local buf = g_Buffers[curl]
	g_Buffers[curl] = (buf or '')..data
	--Debug.info('onCurlData')
end

local function onCurlDone(curl, errno)
	Debug.info('onCurlDone '..tostring(curl)..' '..tostring(errno))
	local url = g_CurlToUrl[curl]
	local data = g_Buffers[curl] or ''
	local req = g_Requests[url]
	
	g_CurlToUrl[curl] = nil
	g_Buffers[curl] = nil
	g_Requests[url] = nil
	
	local statusCode = curlGetInfo(curl, 'CURLINFO_RESPONSE_CODE')
	if (errno ~= 0 or statusCode ~= 200) then
		Debug.err('Download failed (errno '..errno..', statusCode '..statusCode..')')
		failRequest(req)
	else
		finishRequest(req, url, data)
	end
end

addInitFunc(function()
	addEventHandler('onCurlData', resourceRoot, onCurlData)
	addEventHandler('onCurlDone', resourceRoot, onCurlDone)
end)
