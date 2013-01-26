if(getVersion().sortable < "1.3.0-9.03986.0") then
	local g_ScrW, g_ScrH = guiGetScreenSize ()

	local function intToAlpha(color)
		local a = 16777216
		local red, green, blue, alpha = 0, 0, 0, 0
		local ap = 1
		
		if(color < 0)then
			color = 2147483648 + (-color)
			alpha = 383
			ap = -ap
		end
		
		while(color >= a)do
			alpha = alpha + ap
			color = color - a
		end
		return alpha
	end

	function dxDrawColoredText(text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI)
		-- Making parameters optional.
		right = right or left
		bottom = bottom or top
		color = color or tocolor(255, 255, 255, 255)
		scale = scale or 1
		font = font or "default"
		alignX = alignX or "left"
		alignY = alignY or "top"
		clip = clip or false
		wordBreak = wordBreak or false
		postGUI = postGUI or true
		
		local width = right - left
		local height = bottom - top
		
		local alpha = intToAlpha(color)
		local text_height = dxGetFontHeight(scale, font)
		local text_width = dxGetTextWidth(text:gsub("#%x%x%x%x%x%x", ""), scale, font)
		
		if(alignX == "center") then
			left = left + (width - text_width)/2
		elseif(alignX == "right") then
			left = right - text_width
		end
		if(alignY == "center") then
			top = top + (height - text_height)/2
		elseif(alignY == "bottom") then
			top = top - text_height
		end
		
		local offset = 0
		
		-- 0 index ?
		local col1, col2 = string.find(text, "#%x%x%x%x%x%x")
		if col1 ~= nil then col1 = col1-1 end
		
		-- draw text with the color we sent until we find hexadecimal code.
		for i = 1, col1 or string.len(text) do
			text_width = dxGetTextWidth(string.sub(text, i, i), scale, font)
			dxDrawText(string.sub(text, i, i), left + offset, top, right, bottom, color, scale, font, "left", "top", clip, wordBreak, postGUI)
			offset = offset + text_width
		end
		
		while(string.find(text, "#%x%x%x%x%x%x", i)) do
			local hex1, hex2 = string.find(text, "#%x%x%x%x%x%x")
			local r, g, b, a = getColorFromString(string.sub(text, hex1, hex2))
			text = string.sub(text, hex2 + 1)
			hex1, hex2 = string.find(text, "#%x%x%x%x%x%x")
			if hex1 ~= nil then hex1 = hex1-1 end
			for i = 1, hex1 or string.len(text) do
				text_width = dxGetTextWidth(string.sub(text, i, i), scale, font)
				dxDrawText(string.sub(text, i, i), left + offset, top, right, bottom, tocolor(r, g, b, alpha), scale, font, "left", "top", clip, wordBreak, postGUI)
				offset = offset + text_width
			end
		end
	end
else
	function dxDrawColoredText(text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI)
		dxDrawText(text, left, top, right or left, bottom or top,
			color or tocolor(255, 255, 255), scale or 1, font or "default",
			alignX or "left", alignY or "top",
			clip or false, wordBreak or false, postGUI or false, true)
	end
end