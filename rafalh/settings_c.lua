g_Settings = {}
g_ClientSettings = {}
local g_SettingFunctions = {}

function tobool ( val )
	return ( val == true or val == "true" or val == 1 )
end

function SmRegister ( name, default, func )
	g_SettingFunctions[name] = func
	g_ClientSettings[name] = default
end

SmRegister ( "suicide_key", "k" )
SmRegister ( "stats_panel_key", "F1" )
SmRegister ( "user_panel_key", "F2" )
SmRegister ( "effects", {}, tobool )
SmRegister ( "radio_channel", "" )
SmRegister ( "radio_volume", 100, touint )

g_SettingsInfo = {
	suicide_key = { def = "k", f = tostring },
	stats_panel_key = {},
	effects = {def = {}, tostring}}

function loadSettings ()
	local node = xmlLoadFile ( "settings.xml" )
	if ( not node ) then return end
	
	for i, subnode in ipairs ( xmlNodeGetChildren ( node ) ) do
		local name = xmlNodeGetName ( subnode )
		local setting = g_ClientSettings[name]
		local func = g_SettingFunctions[name]
		
		if ( setting ) then
			local val = xmlNodeGetValue ( subnode )
			local attr = xmlNodeGetAttributes ( subnode )
			
			if ( func ) then
				val = func ( val )
			end
			
			if ( type ( setting ) == "table" ) then
				if ( attr.name ) then
					setting[attr.name] = val
				end
			else
				g_ClientSettings[name] = val
			end
		end
	end
	
	xmlUnloadFile ( node )
end

function saveSettings ()
	local node = xmlCreateFile ( "settings.xml", "settings" )
	if ( not node ) then return end
	
	for name, val in pairs ( g_ClientSettings ) do
		if ( type ( val ) == "table" ) then
			for name2, val2 in pairs ( val ) do
				local subnode = xmlCreateChild ( node, name )
				xmlNodeSetAttribute ( subnode, "name", name2 )
				xmlNodeSetValue ( subnode, tostring ( val2 ) )
			end
		else
			local subnode = xmlCreateChild ( node, name )
			xmlNodeSetValue ( subnode, tostring ( val ) )
		end
	end
	
	xmlSaveFile ( node )
	xmlUnloadFile ( node )
end