local g_Requests = {}

addEvent ( "onHttpResult" )

--[[local function DbgPrint ( fmt, ... )
	local path = "log.txt"
	local file = fileExists ( path ) and fileOpen ( path ) or fileCreate ( path )
	if ( file ) then
		fileSetPos ( file, fileGetSize ( file ) )
		fileWrite ( file, fmt:format ( ... ) )
		fileClose ( file )
	else
		outputDebugString ( "Failed to open "..path, 2 )
	end
end]]

--[[local function DbgPrint ( fmt, ... )
	outputDebugString ( fmt:format ( ... ), 3 )
end]]

local function HttpParseHeader ( header )
	local status_line_end = header:find ( "\r\n" ) or header:len ()
	
	local status_line = header:sub ( 1, status_line_end - 1 )
	local hdr_fields = header:sub ( status_line_end + 2 )
	
	local ver, status, reason = status_line:match ( "^HTTP/(%d.%d)%s+(%d+)%s+(.*)$" )
	if ( not ver ) then
		return false
	end
	if(ver ~= "1.0" and ver ~= "1.1") then
		outputDebugString("Unknown HTTP version "..ver, 2)
	end
	status = tonumber ( status )
	
	local fields = {}
	for name, value in hdr_fields:gmatch ( "([%w-]+):%s([^\r\n]+)\r\n" ) do
		fields[name] = value
	end
	
	return status, reason, fields
end

local function HttpSockData ( sock, data )
	--DbgPrint ( "HttpSockData (%u bytes):", data:len () )
	--DbgPrint ( "%s", data )
	--outputDebugString("HttpSockData", 3)
	
	local req = g_Requests[sock]
	if ( not req ) then
		outputDebugString("Unknown socket", 2)
		return
	end
	
	req.buf = req.buf..data
	req.debugBuf = (req.debugBuf or "")..data
	resetTimer ( req.timer )
	
	if ( not req.hdr ) then
		local hdr_end = req.buf:find ( "\r\n\r\n" )
		if ( hdr_end ) then
			local header = req.buf:sub ( 1, hdr_end - 1 + 2 ) -- don't remove first "\r\n"
			req.status, req.reason, req.hdr = HttpParseHeader ( header )
			req.buf = req.buf:sub ( hdr_end + 4 )
		end
	end
	
	if(req.hdr) then
		local finished = false
		if(not req.hdr["Transfer-Encoding"]) then
			req.data = (req.data or "")..req.buf
			req.buf = ""
			
			if(not req.hdr["Content-Length"]) then
				outputDebugString("Unknown content length", 2)
				if(not req.debug) then
					req.debug = true
					local file = fileCreate("httpdbg.txt")
					if(file) then
						fileWrite(file, req.debugBuf)
						fileClose(file)
					end
				end
			else
				local len = tonumber ( req.hdr["Content-Length"] )
				if ( len and req.data:len () >= len ) then
					finished = true
				else
					--outputDebugString("Http transfer in progress "..req.data:len ().."/"..len, 3)
				end
			end
		elseif(req.hdr["Transfer-Encoding"] == "chunked") then
			local lines = split(req.buf, "\r\n")
			while(#lines > 0) do
				local c = tonumber("0x"..lines[1])
				if(not c) then
					outputDebugString("Invalid chunk "..tostring(lines[1]), 2)
					break
				elseif(c == 0) then
					finished = true
					break
				elseif(lines[2] and c == lines[2]:len()) then
					req.data = (req.data or "")..lines[2]
					table.remove(lines, 1)
					table.remove(lines, 1)
				else
					break
				end
			end
			req.buf = table.concat(lines, "\r\n")
		else
			outputDebugString("Unknown encoding "..req.hdr["Transfer-Encoding"], 2)
		end
		
		--[[if(false) then
			local ignoredHeaders = {
				["Date"] = true, ["Server"] = true, ["Last-Modified"] = true,
				["Content-Type"] = true, ["Etag"] = true, ["Accept-Ranges"] = true,
				["Transfer-Encoding"] = true}
			local unkHdrNames = {}
			for key, value in pairs(req.hdr) do
				if(not ignoredHeaders[key]) then
					table.insert(unkHdrNames, key.."="..value)
				end
			end
			if(#unkHdrNames > 0) then
				outputDebugString("Unknown headers "..table.concat(unkHdrNames, ", "), 2)
			end
		end]]
		
		if(finished) then
			--DbgPrint ( "Transfer finished: %u", len )
			--outputDebugString("Http transfer finished", 3)
			sockClose ( sock )
		end
	end
end

local function HttpSockOpened ( sock )
	--DbgPrint ( "HttpSockOpened" )
	--outputDebugString("HttpSockOpened", 3)
	
	local req = g_Requests[sock]
	if ( not req ) then
		outputDebugString("Unknown socket", 2)
		return
	end
	
	local rel_url = req.rel_url ~= "" and req.rel_url or "/"
	local hdr_str = ""
	
	req.hdr["Accept-Encoding"] = "identity"
	req.hdr["Connection"] = "close"
	for name, value in pairs ( req.hdr ) do
		hdr_str = name..": "..value.."\r\n"
	end
	
	sockWrite ( sock,
		( req.verb or "GET" ).." "..rel_url.." HTTP/1.1\r\n".. -- use 1.0 to avoid chunked output
		"Host: "..req.host.."\r\n"..
		hdr_str.."\r\n"..( req.data or "" ) )
	
	req.hdr = false
	req.data = false
	req.buf = ""
end

local function HttpSockClosed ( sock )
	--DbgPrint ( "HttpSockClosed" )
	--outputDebugString("HttpSockClosed", 3)
	
	local req = g_Requests[sock]
	if ( not req ) then
		outputDebugString("Unknown socket", 2)
		return
	end
	
	g_Requests[sock] = nil
	if ( req.timer ) then
		killTimer ( req.timer )
	end
	
	if ( req.el ) then
		--outputDebugString("http result "..tostring(req.data), 3)
		local data = req.data
		if(not req.status or req.status < 200 or req.status >= 300) then
			data = false
		end
		triggerEvent ( "onHttpResult", req.el, data, unpack ( req.args ) )
		destroyElement ( req.el )
	end
	
	--DbgPrint ( "http %u (%s) for %s: %u bytes", req.status, req.reason, req.rel_url, req.data:len () )
end

local function HttpTimeout ( sock )
	local req = g_Requests[sock]
	assert ( req )
	
	outputDebugString ( "Http connection timed out "..req.host.."/"..req.rel_url, 2 )
	
	if ( req.el ) then
		triggerEvent ( "onHttpResult", req.el, false, unpack ( req.args ) )
		destroyElement ( req.el )
		req.el = false
	end
	
	req.timer = false
	
	sockClose ( sock )
end

local function HttpOnRequestDestroy ()
	local sock = getElementData ( source, "http_sock" )
	local req = sock and g_Requests[sock]
	if ( req ) then
		req.el = false
		sockClose ( sock )
	end
end

function HttpSendRequest ( url, header_fields, verb, data, ... )
	local req = { hdr = header_fields or {}, verb = verb, data = data, args = { ... } }
	local proto, pos = url:match ( "^(%w+)://()" )
	
	if ( proto and proto ~= "http" ) then
		outputDebugString ( "Unsupported protocol "..tostring ( proto ), 2 )
		return false
	end
	
	url = url:sub ( pos or 1 )
	req.host, req.rel_url = url:match ( "^([^/]+)(/?.*)$" )
	
	local sock = sockOpen ( req.host, 80 )
	if ( not sock ) then
		outputDebugString ( "Failed to open socket for "..tostring ( req.host ), 2 )
		return false
	end
	
	req.timer = setTimer ( HttpTimeout, 5000, 1, sock )
	req.el = createElement ( "http_req" )
	setElementData ( req.el, "http_sock", sock, false )
	addEventHandler ( "onElementDestroy", req.el, HttpOnRequestDestroy )
	
	g_Requests[sock] = req
	return req.el
end

function HttpEncodeUrl ( url )
	url = url:gsub ( "([^a-zA-Z0-9 ])", function ( ch ) return ( "%%%02X" ):format ( ch:byte () ) end )
	url = url:gsub ( " ", "+" )
	return url
end

addEventHandler ( "onSockOpened", g_Root, HttpSockOpened )
addEventHandler ( "onSockClosed", g_Root, HttpSockClosed )
addEventHandler ( "onSockData", g_Root, HttpSockData )
