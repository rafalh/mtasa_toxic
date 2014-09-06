local g_EffectInfo = {
	name = {"Dynamic Sky", pl = "Dynamiczne niebo"},
	res = resource,
}

local g_AutoEnable = false

local g_Enabled = false
local g_Changed = false

addEvent('toxic.onEffectInfo')
addEvent('toxic.onEffectInfoReq')

function setEffectEnabled(enable)
	g_Changed = true
	if(enable == g_Enabled) then return true end
	
	if(not enable) then
		stopShaderResource()
	else
		startShaderResource()
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
	triggerEvent('toxic.onEffectInfo', resourceRoot, g_EffectInfo)
	addEventHandler('toxic.onEffectInfoReq', resourceRoot, function()
		triggerEvent('toxic.onEffectInfo', resourceRoot, g_EffectInfo)
	end)
end)
