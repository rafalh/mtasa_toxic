local g_EffectName = { "Realistic Water", pl = "Realistyczna woda" }
local g_AutoEnable = true

local g_Enabled = false
local g_Changed = false

addEvent ( "onRafalhAddEffect" )
addEvent ( "onRafalhGetEffects" )

function setEffectEnabled ( enable )
	g_Changed = true
	if ( enable == g_Enabled ) then return true end
	
	if ( not enable ) then
		disableWater()
	elseif(not enableWater()) then
		return false
	end
	g_Enabled = enable
	
	return true
end

function isEffectEnabled ()
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
