-- Exported
function HttpHandleRequest(req)
	if(type(req) ~= 'table' or not req.hdrs or not req.params or not req.cookies or not req.ip or not req.url) then return end
	
	req.account = user
	
	-- Note: MTA doesn't url-decode anything
	req.url = urlDecode(req.url)
	for k, v in pairs(req.params) do
		req.params[k] = urlDecode(v)
	end
	for k, v in pairs(req.cookies) do
		req.cookies[k] = urlDecode(v)
	end
	
	-- Calculate path
	req.path = req.url
	if(req.path:beginsWith('/'..g_ResName)) then
		req.path = req.path:sub(g_ResName:len() + 2)
	end
	req.path = req.path:gsub('%?.+$', '')
	
	-- Get response
	return Http.handleReq(req)
end

namespace('Http')

local g_Routes = {}

function addRoute(path, handler)
	g_Routes[path] = handler
end

function handleReq(req)
	local response = Response()
	
	local path = req.path
	if(not g_Routes[path] and req.params.path) then
		path = req.params.path
	end
	
	local handler = g_Routes[path]
	if(handler) then
		handler(req, response)
	else
		response:write('Invalid route: '..tostring(path)..'!')
		response.status = 404
	end
	
	response:finish()
	return response
end

function url(path, params)
	local tmp = {}
	for k, v in pairs(params or {}) do
		table.insert(tmp, '&'..urlEncode(k)..'='..urlEncode(v))
	end
	return '/'..g_ResName..'/http/index.html?path='..urlEncode(path)..table.concat(tmp)
end

Response = Class('Response')

function Response.__mt.__index:write(str)
	table.insert(self.buf, str)
end

function Response.__mt.__index:setHeader(name, val)
	self.hdrs[name] = val
end

function Response.__mt.__index:init()
	self.status = 200
	self.buf = {}
	self.hdrs = {}
	self.cookies = {}
end

function Response.__mt.__index:finish()
	if(self.buf) then
		self.data = table.concat(self.buf)
		self.buf = nil
	end
end

function Response.__mt.__index:redirect(path, params)
	self.status = 302
	self:setHeader('Location', url(path, params))
end

function Response.__mt.__index:beginPage(title)
	self:setHeader('Content-Type', 'text/html; charset=utf-8')
	self:write(
	'<html><head>'..
		'<title>'..title..'</title>'..
		'<link rel="stylesheet" type="text/css" href="/'..g_ResName..'/http/style.css" />'..
	'</head><body>')
end

function Response.__mt.__index:endPage()
	self:write('</body></html>')
end

--[[function Response.__mt.__newindex(self, k, v)
	assert(false, tostring(k)..' '..tostring(v))
end]]
