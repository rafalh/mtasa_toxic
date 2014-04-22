namespace('GUI')
local g_TempLabel

local function prepareTempLabel(font)
	if(not g_TempLabel) then
		g_TempLabel = guiCreateLabel(0, 0, 0, 0, '', false)
		if(not g_TempLabel) then return false end
		guiSetVisible(g_TempLabel, false)
	end
	if(not guiSetFont(g_TempLabel, font or 'default-normal')) then return false end
	return true
end

function getTextWidth(text, font)
	if(not prepareTempLabel(font)) then return false end
	if(not guiSetText(g_TempLabel, text)) then return false end
	return guiLabelGetTextExtent(g_TempLabel)
end

function getFontHeight(font)
	if(not font or font == 'default-normal') then return 15 end -- HACK
	if(not prepareTempLabel(font)) then return false end
	return guiLabelGetFontHeight(g_TempLabel)
end

function wordWrap(str, maxW, font)
	local tbl = {}
	
	while(str:len() > 0) do
		local c = str:len()
		local sub
		
		while(true) do
			sub = str:sub(1, c)
			local w = getTextWidth(sub, font)
			if(w < maxW) then break end
			
			local subRev = sub:reverse()
			local idxRev = subRev:find(' ', 1, true)
			local newC = c - idxRev
			if(newC == 0) then break end
			
			c = newC
		end
		
		assert(sub:len() > 0)
		table.insert(tbl, sub)
		str = str:sub(1 + c + 1)
	end
	
	return tbl
end

function scrollPaneAddMouseWheelSupport(scrollPane, factor)
	if(not factor) then factor = 10 end
	addEventHandler('onClientMouseWheel', scrollPane, function(upOrDown)
		--Debug.info('Scroll '..getElementType(source)..'!')
		
		local elType = getElementType(source)
		if(source ~= scrollPane and (elType == 'gui-scrollpane' or elType == 'gui-scrollbar')) then
			return -- ignore
		end
		
		-- Scroll the pane
		local pos = guiScrollPaneGetVerticalScrollPosition(scrollPane)
		pos = pos - upOrDown * factor
		guiScrollPaneSetVerticalScrollPosition(scrollPane, pos)
	end, true)
	
	-- Disable built-in scrolling
	guiSetProperty(scrollPane, 'VertStepSize', '0')
end
