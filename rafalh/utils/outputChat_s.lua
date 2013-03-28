function divChatStr ( str )
	local tbl = {}
	
	while ( str:len () > 0 ) do
		local t = str:sub ( 1, 128 ):reverse ():find ( " " )
		local part = str:sub ( 1, ( t and ( 129 - t ) ) or 128 )
		table.insert ( tbl, part )
		str = str:sub ( part:len () + 1 )
	end
	
	return tbl
end

function privMsg ( player, fmt, ... )
	local msg = "PM: "..MuiGetMsg ( fmt, player ):format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
	local is_console = getElementType ( player ) == "console"
	
	if ( is_console ) then
		outputServerLog ( msg )
	else
		local parts = divChatStr ( msg )
		
		for i, part in ipairs ( parts ) do
			outputChatBox ( part, player, 255, 96, 96, false )
		end
	end
end

function scriptMsg ( fmt, ... )
	if ( g_ScriptMsgState.recipients[1] == g_Root ) then -- everybody is a recipient
		local part = g_ScriptMsgState.prefix..fmt:format ( ... ):gsub ( "#%x%x%x%x%x%x", "" ):sub ( 1, 128 )
		
		--outputServerLog ( part )
		
		local rafalh_webchat_res = getResourceFromName ( "rafalh_webchat" )
		if ( rafalh_webchat_res and getResourceState ( rafalh_webchat_res ) == "running" ) then
			call ( rafalh_webchat_res, "addChatStr", "#ffc46e"..part )
		end
	end
	
	local recipients = {}
	for i, element in ipairs ( g_ScriptMsgState.recipients ) do
		for i, player in ipairs ( getElementsByType ( "player", element ) ) do
			table.insert ( recipients, player )
		end
		for i, console in ipairs ( getElementsByType ( "console", element ) ) do
			table.insert ( recipients, console )
		end
	end
	
	local r, g, b = 255, 196, 128
	if ( g_ScriptMsgState.color ) then
		r, g, b = getColorFromString ( g_ScriptMsgState.color )
	end
	
	for i, player in ipairs ( recipients ) do
		local msg = g_ScriptMsgState.prefix..MuiGetMsg ( fmt, player ):format ( ... ):gsub ( "#%x%x%x%x%x%x", "" )
		local parts = divChatStr ( msg )
		local is_console = getElementType ( player ) == "console"
		
		for i, part in ipairs ( parts ) do
			if ( is_console ) then
				outputServerLog ( part )
			else
				outputChatBox ( part, player, r, g, b, false )
			end
		end
	end
end

local function formatMsg(style, onlyCodes, fmt, ...)
	local curClr = not onlyCodes and style[1]
	
	local ret = ""
	local r, g, b
	local args = {...}
	
	local i, argi = 1, 1
	while(true) do
		local b, e = fmt:find("%%%d*%.?%d*l?h?[diuxXfs]", i)
		if(not b) then break end
		
		local str, clr
		
		if(b > i) then
			if(curClr ~= style[1]) then
				ret = ret..style[1]
				curClr = style[1]
			end
			ret = ret..fmt:sub(i, b - 1)
		end
		
		local str = fmt:sub(b, e):format(args[argi])
		argi = argi + 1
		
		if(curClr ~= style[2]) then
			ret = ret..style[2]
			curClr = style[2]
		end
		ret = ret..str
		
		if(str:find("#%x%x%x%x%x%x")) then
			curClr = false
		end
		
		i = e + 1
	end
	
	if(i <= fmt:len()) then
		if(curClr ~= style[1]) then
			ret = ret..style[1]
		end
		ret = ret..fmt:sub(i)
	end
	
	if(not onlyCodes) then
		r, g, b = getColorFromString(style[1])
	end
	
	return ret, r, g, b
end

function outputMsg(visibleTo, style, fmt, ...)
	if(type(visibleTo) == "table") then
		visibleTo = visibleTo.el
	elseif(not visibleTo) then
		visibleTo = g_Root
	end
	if(type(style) == "string") then
		style = {style, style}
	elseif(not style) then
		style = {"#FFC080", "#FFFFFF"}
	end
	
	if(visibleTo == g_Root or getElementType(visibleTo) == "game-room") then
		local msg = fmt:format(...):gsub("#%x%x%x%x%x%x", "")
		outputServerLog(msg)
		
		local webChatRes = getResourceFromName("rafalh_webchat")
		if(webChatRes and getResourceState(webChatRes) == "running") then
			local msg = formatMsg(style, true, fmt, ...)
			call(webChatRes, "addChatStr", msg)
		end
	end
	
	--local r, g, b = getColorFromString(color)
	local localeCache = {}
	for i, player in ipairs(getElementsByType("player", visibleTo)) do
		local msg, r, g, b
		
		local locale = MuiGetPlayerLocale(player)
		if(localeCache[locale]) then
			msg, r, g, b = unpack(localeCache[locale])
		else
			msg, r, g, b = formatMsg(style, false, MuiGetMsg(fmt, player), ...)
			localeCache[locale] = {msg, r, g, b}
		end
		
		outputChatBox(msg, player, r, g, b, true)
	end
end