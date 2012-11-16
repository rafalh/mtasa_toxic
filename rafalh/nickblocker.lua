local g_BannedNames = {}

local function NbCheckName ( name )
	name = name:lower ()
	for i, pattern in ipairs ( g_BannedNames ) do
		if ( name:match ( pattern ) ) then
			return true
		end
	end
	return false
end

local function NbInit ()
	local node, i = xmlLoadFile ( "conf/banned_names.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "name", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local pattern = xmlNodeGetValue ( subnode )
			assert ( pattern )
			table.insert ( g_BannedNames, pattern )
		end
		xmlUnloadFile ( node )
	end
	
	for player, pdata in pairs ( g_Players ) do
		if ( NbCheckName ( getPlayerName ( player ) ) ) then
			setPlayerName ( player, "ToxicPlayer"..tostring ( math.random ( 0, 9999 ) ) )
		end
	end
end

local function NbOnPlayerJoin ()
	if ( wasEventCancelled () ) then return end
	
	if ( NbCheckName ( getPlayerName ( source ) ) ) then
		setPlayerName ( source, "ToxicPlayer"..tostring ( math.random ( 0, 9999 ) ) )
	end
end

local function NbOnPlayerChangeNick ( oldNick, newNick )
	if ( wasEventCancelled () ) then return end
	
	if ( NbCheckName ( newNick ) ) then
		cancelEvent ()
	end
end	

addEventHandler ( "onResourceStart", g_ResRoot, NbInit )
addEventHandler ( "onPlayerJoin", g_Root, NbOnPlayerJoin )
addEventHandler ( "onPlayerChangeNick", g_Root, NbOnPlayerChangeNick )
