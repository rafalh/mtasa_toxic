local function AvCheckPlayer ( player )
	if ( SmGetBool ( "auto_votekick" ) and hasObjectPermissionTo ( player, "command.kick", false ) ) then
		set ( "*votemanager.votekick_enabled", false )
	end
	if ( SmGetBool ( "auto_votemap" ) and hasObjectPermissionTo ( player, "command.setmap", false ) ) then
		set ( "*votemanager.votemap_enabled", false )
	end
end

local function AvOnPlayerLogout ()
	if ( wasEventCancelled () ) then return end
	
	local enable_votekick, enable_votemap = true, true
	local auto_votekick = SmGetBool ( "auto_votekick" )
	local auto_votemap = SmGetBool ( "auto_votemap" )
	
	for player, p in pairs ( g_Players ) do
		if ( auto_votekick and hasObjectPermissionTo ( player, "command.kick", false ) and player ~= source ) then
			enable_votekick = false
		end
		if ( auto_votemap and hasObjectPermissionTo ( player, "command.setmap", false ) and player ~= source ) then
			enable_votemap = false
		end
	end
	
	if ( auto_votekick ) then
		set ( "*votemanager.votekick_enabled", enable_votekick )
	end
	if ( auto_votemap ) then
		set ( "*votemanager.votemap_enabled", enable_votemap )
	end
end

local function AvInit ()
	for player, pdata in pairs ( g_Players ) do
		AvCheckPlayer ( player )
	end
end

local function AvOnPlayerLogin ()
	if ( wasEventCancelled () ) then return end
	
	AvCheckPlayer ( source )
end

addEventHandler ( "onResourceStart", g_ResRoot, AvInit )
addEventHandler ( "onPlayerLogin", g_Root, AvOnPlayerLogin )
addEventHandler ( "onPlayerLogout", g_Root, AvOnPlayerLogout )
addEventHandler ( "onPlayerQuit", g_Root, AvOnPlayerLogout )
