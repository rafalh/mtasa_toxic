local g_InitFuncs = {}
local _addEventHandler

local function setupDatabase()
	if(not DbInit()) then
		return false
	end
	
	if(not Settings.init()) then
		return false
	end
	
	Settings.createDbTbl()
	
	local err = false
	local currentVer = 148
	local ver = Settings.version
	if(ver == 0) then
		ver = touint(get("version")) or currentVer
		Settings.version = currentVer
		outputDebugString("Version: "..ver, 2)
	end
	
	if(ver < currentVer) then
		if(not err and ver < 147) then
			if(not DbQuery("ALTER TABLE "..DbPrefix.."players ADD COLUMN achvCount INT DEFAULT 0 NOT NULL")) then
				err = "Failed to add achvCount column."
			end
		end
		if(not err and ver < 148) then
			if(not DbQuery("ALTER TABLE "..DbPrefix.."settings ADD COLUMN backupTimestamp INT DEFAULT 0 NOT NULL")) then
				err = "Failed to add backupTimestamp column."
			end
		end
		
		if(not err) then
			Settings.version = currentVer
			outputDebugString("Database update (ver "..ver.." -> "..currentVer..") succeeded", 2)
		end
	end
	
	if(err) then
		outputDebugString("Database init (ver "..ver.." -> "..currentVer..") failed: "..tostring(err), 1)
		return false
	end
	
	return true
end

local function setupACL()
	local acl = aclGet("Admin")
	if(not acl) then
		outputDebugString("Cannot find Admin ACL!", 1)
		return false
	end
	
	local rightsToAdd = {}
	local save = false
	
	for i, right in ipairs(CmdGetAclRights()) do
		if(not aclGetRight(acl, right)) then
			table.insert(rightsToAdd, right)
		end
	end
	
	for i, name in ipairs(g_CustomRights) do
		local right = "resource."..g_ResName.."."..name
		if(not aclGetRight(acl, right)) then
			table.insert(rightsToAdd, right)
		end
	end
	
	if(#rightsToAdd > 0) then
		if(hasObjectPermissionTo(resource, "function.aclSetRight") and hasObjectPermissionTo(resource, "function.aclSave")) then
			for i, right in ipairs(rightsToAdd) do
				aclSetRight(acl, right, true)
			end
			aclSave()
			outputDebugString("ACL has been updated", 3)
		else
			outputDebugString("Resource does not have right to change ACL. Add custom rights manually...", 2)
		end
	end
	
	return true
end

local function LoadCountries()
	local node, i = xmlLoadFile("conf/countries.xml"), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild (node, "country", i)
			if(not subnode) then break end
			i = i + 1
			
			local code = xmlNodeGetAttribute(subnode, "code")
			local name = xmlNodeGetAttribute(subnode, "name")
			assert(code and name)
			g_Countries[code:upper ()] = name
		end
		xmlUnloadFile(node)
	end
end

local function LoadLanguages()
	local node, i = xmlLoadFile("conf/iso_langs.xml"), 0
	if(node) then
		while(true) do
			local subnode = xmlFindChild(node, "lang", i)
			if(not subnode) then break end
			i = i + 1
			
			local code = xmlNodeGetAttribute(subnode, "code")
			local name = xmlNodeGetValue(subnode)
			assert(code and name)
			g_IsoLangs[code:upper()] = name
		end
		xmlUnloadFile(node)
	end
end

local function LoadMapTypes()
	local node, i = xmlLoadFile("conf/map_types.xml"), 0
	if ( node ) then
		while ( true ) do
			local subnode = xmlFindChild(node, "type", i)
			if ( not subnode ) then break end
			i = i + 1
			
			local data = {}
			data.name = xmlNodeGetAttribute(subnode, "name")
			data.pattern = xmlNodeGetAttribute(subnode, "pattern")
			
			local gm = xmlNodeGetAttribute(subnode, "ghostmode")
			data.gm = touint(gm) or (gm == "true")
			
			data.others_in_row = 0
			data.max_others_in_row = touint(xmlNodeGetAttribute(subnode, "max_others_in_row"))
			
			local winning_veh_str = xmlNodeGetAttribute(subnode, "winning_vehicles") or ""
			local id_list = split(winning_veh_str, ",")
			local added = false
			local winning_veh = {}
			
			for j, v in ipairs(id_list) do
				local id = touint(v)
				if(id) then
					winning_veh[id] = true
					added = true
				end
			end
			
			if(added) then
				data.winning_veh = winning_veh
			end
			
			data.max_fps = touint(xmlNodeGetAttribute(subnode, "max_fps"))
			
			assert(data.name)
			table.insert(g_MapTypes, data)
		end
		xmlUnloadFile(node)
	end
end

local function setupScoreboard()
	local scoreboardRes = getResourceFromName("scoreboard")
	if(scoreboardRes and getResourceState(scoreboardRes) == "running") then
		call(scoreboardRes, "addScoreboardColumn", "country", g_Root, false, 50, "country_img")
	end
end

local function onResStart(res)
	if(getResourceName(res) == "scoreboard") then
		setTimer(setupScoreboard, 1000, 1)
	end
end

local function init()
	math.randomseed(getTickCount())
	createElement("TXC413b9d90", "TXC413b9d90")
	
	-- Enable addEventHandler function
	addEventHandler = _addEventHandler
	
	if(not setupDatabase() or not setupACL()) then
		cancelEvent()
		return
	end
	
	if(not Settings.cleanup_done) then
		outputDebugString("Cleaning database!", 2)
		DbQuery("UPDATE "..DbPrefix.."players SET online=0")
	end
	Settings.cleanup_done = false
	
	LocaleList.init()
	LoadCountries()
	LoadLanguages()
	LoadMapTypes()
	
	setupScoreboard()
	addEventHandler("onResourceStart", g_Root, onResStart)
	
	for i, playerEl in ipairs (getElementsByType("player")) do
		if(NbCheckPlayerAndFix) then
			NbCheckPlayerAndFix(playerEl)
		end
		
		Player.create(playerEl)
	end
	
	local consoles = getElementsByType("console")
	assert(#consoles == 1)
	Player.create(consoles[1])
	
	for i, func in ipairs(g_InitFuncs) do
		func()
	end
	
	outputDebugString("rafalh script has started!", 3)
end

function addInitFunc(func)
	assert(func)
	table.insert(g_InitFuncs, func)
end

addEventHandler("onResourceStart", g_ResRoot, init)

-- Disable addEventHandler for loading
_addEventHandler = addEventHandler
function addEventHandler(...)
	outputDebugString("addEventHandler is not recommended at startup! Use addInitFunc instead.", 2)
	DbgTraceBack()
	_addEventHandler(...)
end
