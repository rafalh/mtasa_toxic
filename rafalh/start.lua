--------------------------------
-- Local function definitions --
--------------------------------

local function setupDatabase ()
	--g_Db = Database:create ()
	DbInit ()
	local err = false
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_players ("..
			"player INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"..
			"serial VARCHAR(32) NOT NULL,"..
			"account TEXT UNIQUE,"..
			"cash INTEGER DEFAULT 0 NOT NULL,"..
			"points INTEGER DEFAULT 0 NOT NULL,"..
			"warnings INTEGER DEFAULT 0 NOT NULL,"..
			"dm INTEGER DEFAULT 0 NOT NULL,"..
			"dm_wins INTEGER DEFAULT 0 NOT NULL,"..
			"first INTEGER DEFAULT 0 NOT NULL,"..
			"second INTEGER DEFAULT 0 NOT NULL,"..
			"third INTEGER DEFAULT 0 NOT NULL,"..
			"time_here INTEGER DEFAULT 0 NOT NULL,"..
			"first_visit INTEGER DEFAULT 0 NOT NULL,"..
			"last_visit INTEGER DEFAULT 0 NOT NULL,"..
			"bidlvl INTEGER DEFAULT 1 NOT NULL,"..
			"ip VARCHAR(16) DEFAULT '' NOT NULL,"..
			"name VARCHAR(32) DEFAULT '' NOT NULL,"..
			"joinmsg VARCHAR(128) DEFAULT NULL,"..
			"pmuted BOOL DEFAULT 0 NOT NULL,"..
			"toptimes_count INTEGER DEFAULT 0 NOT NULL,"..
			"online BOOL DEFAULT 0 NOT NULL,"..
			"lang VARCHAR(2) DEFAULT '' NOT NULL,"..
			"exploded INTEGER DEFAULT 0 NOT NULL,"..
			"drowned INTEGER DEFAULT 0 NOT NULL,"..
			"locked_nick BOOL DEFAULT 0 NOT NULL,"..
			"invitedby INTEGER DEFAULT 0 NOT NULL,"..
			"health100 INTEGER DEFAULT 0 NOT NULL,"..
			"selfdestr INTEGER DEFAULT 0 NOT NULL,"..
			"mines INTEGER DEFAULT 0 NOT NULL,"..
			"oil INTEGER DEFAULT 0 NOT NULL,"..
			"beers INTEGER DEFAULT 0 NOT NULL,"..
			"invisibility INTEGER DEFAULT 0 NOT NULL,"..
			"godmodes30 INTEGER DEFAULT 0 NOT NULL,"..
			"flips INTEGER DEFAULT 0 NOT NULL,"..
			"thunders INTEGER DEFAULT 0 NOT NULL,"..
			"smoke INTEGER DEFAULT 0 NOT NULL,"..
			"efectiveness REAL DEFAULT 0 NOT NULL,"..
			"efectiveness_dd REAL DEFAULT 0 NOT NULL,"..
			"efectiveness_dm REAL DEFAULT 0 NOT NULL,"..
			"efectiveness_race REAL DEFAULT 0 NOT NULL)" ) ) then
		err = "Cannot create rafalh_players table."
	end
	if ( not err and not DbQuery (
			"CREATE INDEX IF NOT EXISTS rafalh_players_idx ON rafalh_players (account)" ) ) then
		err = "Cannot create rafalh_players_idx index."
	end
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_names ("..
			"player INTEGER NOT NULL,"..
			"name VARCHAR(32) NOT NULL)" ) ) then
		err = "Cannot create rafalh_names table."
	end
	if ( not err and not DbQuery (
			"CREATE INDEX IF NOT EXISTS rafalh_names_idx ON rafalh_names (player)" ) ) then
		err = "Cannot create rafalh_names_idx index."
	end
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_rates ("..
			"player INTEGER NOT NULL,"..
			"map INTEGER NOT NULL,"..
			"rate TINYINT NOT NULL)" ) ) then
		err = "Cannot create rafalh_rates table."
	end
	if ( not err and not DbQuery (
			"CREATE INDEX IF NOT EXISTS rafalh_rates_idx ON rafalh_rates (map)" ) ) then
		err = "Cannot create rafalh_rates_idx index."
	end
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_besttimes ("..
			"player INTEGER NOT NULL,"..
			"map INTEGER NOT NULL,"..
			"time INTEGER NOT NULL,"..
			"rec TEXT DEFAULT '' NOT NULL,"..
			"cp_times TEXT DEFAULT '' NOT NULL,"..
			"timestamp INTEGER)" ) ) then
		err = "Cannot create rafalh_besttimes table."
	end
	if ( not err and not DbQuery (
			"CREATE INDEX IF NOT EXISTS rafalh_besttimes_idx ON rafalh_besttimes (map)" ) ) then
		err = "Cannot create rafalh_besttimes_idx index."
	end
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_profiles ("..
			"player INTEGER NOT NULL,"..
			"field VARCHAR(64) NOT NULL,"..
			"value VARCHAR(255) NOT NULL)" ) ) then
		err = "Cannot create rafalh_profiles table."
	end
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_maps ("..
			"map INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"..
			"name VARCHAR(255) NOT NULL,"..
			"played INTEGER DEFAULT 0 NOT NULL,"..
			"rates INTEGER DEFAULT 0 NOT NULL,"..
			"rates_count INTEGER DEFAULT 0 NOT NULL,"..
			"removed VARCHAR(255) DEFAULT '' NOT NULL,"..
			"played_timestamp NTEGER DEFAULT 0 NOT NULL)" ) ) then
		err = "Cannot create rafalh_maps table."
	end
	
	if ( not err and not DbQuery (
			"CREATE TABLE IF NOT EXISTS rafalh_settings ("..
			"version INTEGER DEFAULT 0 NOT NULL,"..
			"avg_players REAL DEFAULT 0 NOT NULL,"..
			"arit_avg_players_m INTEGER DEFAULT 0 NOT NULL,"..
			"cleanup_done BOOL DEFAULT 0 NOT NULL)" ) ) then
		err = "Cannot create rafalh_settings table."
	end
	
	local current_ver = 136
	local ver = SmGetUInt ( "version", current_ver )
	if ( ver == 0 ) then
		ver = touint ( get ( "version" ) ) or current_ver
		set ( "version", false )
		SmSet ( "version", current_ver )
		outputDebugString ( "Version: "..ver, 2 )
	end
	
	if ( ver < current_ver ) then
		if ( not err and ver < 134 ) then
			if ( not DbQuery ( "ALTER TABLE rafalh_players ADD COLUMN smoke INTEGER DEFAULT 0 NOT NULL" ) ) then
				err = "Failed to add smoke column."
			end
		end
		if ( not err and ver < 135 ) then
			if ( not DbQuery ( "ALTER TABLE rafalh_maps ADD COLUMN played_timestamp INTEGER DEFAULT 0 NOT NULL" ) ) then
				err = "Failed to add played_timestamp column."
			end
		end
		if ( not err and ver < 136 ) then
			if ( not DbQuery ( "ALTER TABLE rafalh_players ADD COLUMN account TEXT" ) ) then
				err = "Failed to add account column."
			end
		end
		
		if ( not err ) then
			SmSet ( "version", current_ver )
			outputDebugString ( "Database update ("..ver.." -> "..current_ver..") succeeded", 2 )
		end
	end
	
	if ( err ) then
		outputDebugString ( "Database update ("..ver.." -> "..current_ver..") failed: "..tostring ( err ), 1 )
		return false
	end
	
	return true
end

local function setupACL ()
	local acl = aclGet ( "Admin" )
	if ( acl ) then
		local save = false
		
		for i, right in ipairs ( CmdGetAclRights () ) do
			if ( not aclGetRight ( acl, right ) ) then
				aclSetRight ( acl, right, true )
				save = true
			end
		end
		
		for i, right in ipairs ( g_CustomRights ) do
			local right2 = "resource.rafalh."..right
			if ( not aclGetRight ( acl, right2 ) ) then
				aclSetRight ( acl, right2, true )
				save = true
			end
		end
		
		if ( save ) then
			aclSave ()
		end
		
		return true
	else
		outputDebugString ( "Cannot find Admin ACL!", 1 )
		return false
	end
end

local function LoadCountries ()
	local node, i = xmlLoadFile ( "conf/countries.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "country", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local code = xmlNodeGetAttribute ( subnode, "code" )
			local name = xmlNodeGetAttribute ( subnode, "name" )
			assert ( code and name )
			g_Countries[code:upper ()] = name
		end
		xmlUnloadFile ( node )
	end
end

local function LoadLanguages ()
	local node, i = xmlLoadFile ( "conf/iso_langs.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "lang", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local code = xmlNodeGetAttribute ( subnode, "code" )
			local name = xmlNodeGetValue ( subnode )
			assert ( code and name )
			g_IsoLangs[code:upper ()] = name
		end
		xmlUnloadFile ( node )
	end
end

local function LoadMapTypes ()
	local node, i = xmlLoadFile ( "conf/map_types.xml" ), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild ( node, "type", i )
			if ( not subnode ) then break end
			i = i + 1
			
			local data = {}
			data.name = xmlNodeGetAttribute ( subnode, "name" )
			data.pattern = xmlNodeGetAttribute ( subnode, "pattern" )
			
			local gm = xmlNodeGetAttribute ( subnode, "ghostmode" )
			data.gm = touint ( gm ) or ( gm == "true" )
			
			data.others_in_row = 0
			data.max_others_in_row = touint ( xmlNodeGetAttribute ( subnode, "max_others_in_row" ) )
			
			local winning_veh_str = xmlNodeGetAttribute ( subnode, "winning_vehicles" ) or ""
			local id_list = split ( winning_veh_str, "," )
			local added = false
			local winning_veh = {}
			
			for j, v in ipairs ( id_list ) do
				local id = touint ( v )
				if ( id ) then
					winning_veh[id] = true
					added = true
				end
			end
			
			if ( added ) then
				data.winning_veh = winning_veh
			end
			
			data.max_fps = touint ( xmlNodeGetAttribute ( subnode, "max_fps" ) )
			
			assert ( data.name )
			table.insert ( g_MapTypes, data )
		end
		xmlUnloadFile ( node )
	end
end

local function onResourceStart ( resource )
	math.randomseed ( getTickCount () )
	createElement ( "TXC413b9d90", "TXC413b9d90" )
	
	if ( not setupDatabase () or not setupACL () ) then
		cancelEvent ()
		return
	end
	
	if ( not SmGetBool ( "cleanup_done" ) ) then
		outputDebugString ( "Cleaning database!", 2 )
		DbQuery ( "UPDATE rafalh_players SET online=0" )
	end
	SmSet ( "cleanup_done", false )
	
	LngInit ()
	LoadCountries ()
	LoadLanguages ()
	LoadMapTypes ()
	
	local scoreboard_res = getResourceFromName ( "scoreboard" )
	if ( scoreboard_res and getResourceState ( scoreboard_res ) == "running" ) then
		call ( scoreboard_res, "addScoreboardColumn", "country", g_Root, false, 50, "country_img" )
	end
	
	for i, playerEl in ipairs ( getElementsByType ( "player" ) ) do
		Player.create(playerEl)
	end
	
	local consoles = getElementsByType ( "console" )
	assert ( #consoles == 1 )
	Player.create(consoles[1])
	
	local auto_clean_db_interval = SmGetUInt ( "auto_clean_db_interval", 0 )
	if ( auto_clean_db_interval > 0 ) then
		DbQuery ( "VACUUM" )
		setTimer ( DbQuery, auto_clean_db_interval * 1000 * 60, 0, "VACUUM" )
	end
	
	outputDebugString ( "rafalh script has started!", 3 )
end

------------
-- Events --
------------

addEventHandler ( "onResourceStart", g_ResRoot, onResourceStart )
