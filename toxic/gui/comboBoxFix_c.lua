-- Combo Box HACKFIX: clicking outside any item doesnt change selected item visually, but guiComboBoxGetSelected returns -1
local g_ComboBoxSelectedItem = {}
local _guiCreateComboBox = guiCreateComboBox
local _guiComboBoxGetSelected = guiComboBoxGetSelected
local _guiComboBoxSetSelected = guiComboBoxSetSelected

function guiCreateComboBox(...)
	local comboBox = _guiCreateComboBox(...)
	if (not comboBox) then return false end
	addEventHandler('onClientGUIComboBoxAccepted', comboBox, function()
		local index = _guiComboBoxGetSelected(source)
		g_ComboBoxSelectedItem[source] = index
	end, false, 'high')
	addEventHandler('onClientElementDestroy', comboBox, function()
		g_ComboBoxSelectedItem[source] = nil
	end, false)
	return comboBox
end

-- hook
function guiComboBoxGetSelected(comboBox)
	return g_ComboBoxSelectedItem[comboBox] or -1
end

-- hook
function guiComboBoxSetSelected(comboBox, itemIndex)
	local ret = _guiComboBoxSetSelected(comboBox, itemIndex)
	if (ret) then
		g_ComboBoxSelectedItem[comboBox] = itemIndex
	end
	return ret
end
