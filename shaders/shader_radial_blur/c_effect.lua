local g_EffectName = { "Radial Blur", pl = "Rozmycie promieniste" }
local g_AutoEnable = false

local g_Enabled = false
local g_Changed = false

addEvent ( "onRafalhAddEffect" )
addEvent ( "onRafalhGetEffects" )

function setEffectEnabled ( enable )
	g_Changed = true
	if ( g_Enabled == enable ) then return true end
	
	if enable then
		enableRadialBlur ()
	else
		disableRadialBlur ()
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