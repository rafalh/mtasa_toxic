local g_Root = getRootElement ()
local g_EffectName = { "Snow", pl = "Śnieg" }
local g_Enabled = false

addEvent ( "onRafalhAddEffect" )
addEvent ( "onRafalhGetEffects" )

function setEffectEnabled ( enable )
	if ( enable and not g_Enabled ) then
		addEventHandler ( "onClientRender", g_Root, renderParticles )
		g_Enabled = true
	elseif ( not enable and g_Enabled ) then
		removeEventHandler ( "onClientRender", g_Root, renderParticles )
		g_Enabled = false
	end
	return true
end

function isEffectEnabled ()
	return g_Enabled
end

function effectCtrl ( enable )
	if ( enable and not g_Enabled ) then
		addEventHandler ( "onClientRender", g_Root, renderParticles )
		g_Enabled = true
	elseif ( not enable and g_Enabled ) then
		removeEventHandler ( "onClientRender", g_Root, renderParticles )
		g_Enabled = false
	end
	return true
end

addEventHandler( "onClientResourceStart", resourceRoot, function ()
	effectCtrl ( true )
	triggerEvent ( "onRafalhAddEffect", g_Root, getThisResource (), g_EffectName )
	addEventHandler ( "onRafalhGetEffects", g_Root, function ()
		triggerEvent ( "onRafalhAddEffect", g_Root, getThisResource (), g_EffectName )
	end )
end )
