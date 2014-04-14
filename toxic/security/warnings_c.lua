local g_GUI
local DelWarningRight = AccessRight('unwarn')

-- Warn player

local function closeWarnPlayerWnd()
	g_GUI:destroy()
	g_GUI = false
	
	showCursor(false)
end

local function acceptWarnPlayerWnd()
	local reason = trimStr(guiGetText(g_GUI.reason))
	if(reason:len() < 3) then
		outputChatBox("Warning reason is too short!", 255, 0, 0)
		return
	end
	
	RPC('warnPlayerRPC', g_GUI.player, reason):exec()
	closeWarnPlayerWnd()
end

function openWarnPlayerWnd(player)
	if(g_GUI) then return end
	
	g_GUI = GUI.create('warnPlayer')
	guiSetText(g_GUI.name, getPlayerName(player):gsub('#%x%x%x%x%x%x', ''))
	g_GUI.player = player
	
	addEventHandler('onClientGUIClick', g_GUI.ok, acceptWarnPlayerWnd, false)
	addEventHandler('onClientGUIClick', g_GUI.cancel, closeWarnPlayerWnd, false)
	
	showCursor(true)
	guiBringToFront(g_GUI.reason)
end

-- Warnings list

local function closeWarningsWnd()
	g_GUI:destroy()
	g_GUI = false
	
	showCursor(false)
end

local function deleteSelectedWarn()
	local row, col = guiGridListGetSelectedItem(g_GUI.list)
	local id = row and guiGridListGetItemData(g_GUI.list, row, g_GUI.fromCol)
	if(id) then
		RPC('deleteWarningRPC', id):exec()
		guiGridListRemoveRow(g_GUI.list, row)
		local warnsCount = guiGridListGetRowCount(g_GUI.list)
		guiSetText(g_GUI.count, ('%u/%u'):format(warnsCount, Settings.max_warns))
	end
end

function openWarningsWnd(player, warns)
	if(g_GUI) then return end
	
	g_GUI = GUI.create('warningsList')
	guiSetText(g_GUI.name, getPlayerName(player):gsub('#%x%x%x%x%x%x', ''))
	if(Settings.max_warns > 0) then
		guiSetText(g_GUI.count, ('%u/%u'):format(#warns, Settings.max_warns))
	else
		guiSetText(g_GUI.count, tostring(#warns))
	end
	
	if(DelWarningRight:check()) then
		guiSetVisible(g_GUI.delete, true)
	end
	
	g_GUI.player = player
	
	for i, data in ipairs(warns) do
		local row = guiGridListAddRow(g_GUI.list)
		local adminName = data.admin:gsub('#%x%x%x%x%x%x', '')
		local dateStr = formatDate(data.timestamp)
		
		guiGridListSetItemText(g_GUI.list, row, g_GUI.fromCol, adminName, false, false)
		guiGridListSetItemText(g_GUI.list, row, g_GUI.dateCol, dateStr, false, false)
		guiGridListSetItemText(g_GUI.list, row, g_GUI.reasonCol, data.reason, false, false)
		guiGridListSetItemData(g_GUI.list, row, g_GUI.fromCol, data.id)
	end
	
	addEventHandler('onClientGUIClick', g_GUI.close, closeWarningsWnd, false)
	addEventHandler('onClientGUIClick', g_GUI.delete, deleteSelectedWarn, false)
	
	showCursor(true)
end
