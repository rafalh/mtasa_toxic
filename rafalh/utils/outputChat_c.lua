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

function outputMsg(style, fmt, ...)
	if(type(style) == "string") then
		style = {style, style}
	elseif(not style) then
		style = {"#FFC080", "#FFFFFF"}
	end
	
	local msg, r, g, b = formatMsg(style, false, MuiGetMsg(fmt), ...)
	outputChatBox(msg, r, g, b, true)
end
