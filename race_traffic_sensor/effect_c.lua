local g_EffectName = {"Traffic sensor", pl = "Czujnik ruchu"}
local g_AutoEnable = true

local g_Enabled = false
local g_Changed = false

addEvent("onRafalhAddEffect")
addEvent("onRafalhGetEffects")

function setEffectEnabled(enable)
	g_Changed = true
	if(enable == g_Enabled) then return true end
	
	if(enable) then
		TsEnable()
	else
		TsDisable()
	end
	g_Enabled = enable
	return true
end

function isEffectEnabled()
	return g_Enabled
end

local function initDelayed()
	if(not g_Changed) then
		setEffectEnabled(g_AutoEnable)
	end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	setTimer(initDelayed, 1000, 1)
	triggerEvent("onRafalhAddEffect", root, resource, g_EffectName)
	addEventHandler("onRafalhGetEffects", root, function()
		triggerEvent("onRafalhAddEffect", root, resource, g_EffectName)
	end)
end)