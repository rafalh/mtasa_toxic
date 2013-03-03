local g_EffectName = { "Music auto-start", pl = "Auto-start muzyki" }

addEvent ( "onRafalhAddEffect" )
addEvent ( "onRafalhGetEffects" )

function setEffectEnabled ( enable )
	if ( enable == g_AutoStart ) then return true end
	
	g_AutoStart = enable
	return true
end

function isEffectEnabled ()
	return g_AutoStart
end

addEventHandler( "onClientResourceStart", resourceRoot, function ()
	triggerEvent ( "onRafalhAddEffect", root, getThisResource (), g_EffectName )
	addEventHandler ( "onRafalhGetEffects", root, function ()
		triggerEvent ( "onRafalhAddEffect", root, getThisResource (), g_EffectName )
	end )
end )
