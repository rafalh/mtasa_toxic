local g_Settings = {}
local g_PrivateSettings = false

local function SmLoadPrivateSettings()
	if(not DbIsReady()) then
		outputDebugString("Database is not ready yet", 2)
		return
	end
	
	local rows = DbQuery ( "SELECT * FROM rafalh_settings LIMIT 1" )
	if ( not rows[1] ) then
		DbQuery ( "INSERT INTO rafalh_settings DEFAULT VALUES" ) -- Note: DEFAULT VALUES is sqlite only
		rows = DbQuery ( "SELECT * FROM rafalh_settings LIMIT 1" )
	end
	g_PrivateSettings = rows[1]
end

local function SmGetInternal(name)
	if(not g_PrivateSettings) then
		SmLoadPrivateSettings()
	end
	if(g_PrivateSettings[name] ~= nil) then
		--outputDebugString("Get private value "..name..": "..tostring(g_PrivateSettings[name]), 2)
		return g_PrivateSettings[name]
	end
	return get(name)
end

function SmGetStr(name, def_val)
	if(g_Settings[name] == nil) then
		g_Settings[name] = tostring(SmGetInternal(name) or def_val)
	end
	return g_Settings[name]
end

function SmGetInt(name, def_val)
	if(g_Settings[name] == nil) then
		g_Settings[name] = toint(SmGetInternal(name), def_val)
	end
	return g_Settings[name]
end

function SmGetUInt(name, def_val)
	if(g_Settings[name] == nil) then
		g_Settings[name] = touint(SmGetInternal(name), def_val)
	end
	return g_Settings[name]
end

function SmGetNum(name, def_val)
	if(g_Settings[name] == nil) then
		g_Settings[name] = tonum(SmGetInternal(name), def_val)
	end
	return g_Settings[name]
end

function SmGetBool(name, def_val)
	if(g_Settings[name] == nil) then
		local val = SmGetInternal(name)
		g_Settings[name] = tobool(val)
	end
	return g_Settings[name]
end

function SmSet(name, value)
	assert(type(name) == "string")
	if(not g_PrivateSettings) then
		SmLoadPrivateSettings()
	end
	if(g_PrivateSettings[name] ~= nil) then
		g_PrivateSettings[name] = value
		if(type(value) == "boolean") then
			value = value and 1 or 0
		end
		DbQuery("UPDATE rafalh_settings SET "..name.."=?", value)
		--outputDebugString ( "Set private value "..name..": "..value, 2 )
	else
		set(name, value)
	end
	g_Settings[name] = nil
end

local function SmOnSettingChange(name, old_val, new_val)
	local ch1 = name:sub(1, 1)
	if(ch1 == "*" or ch1 == "@") then
		name = name:sub(2)
	end
	
	if(name:sub(1, g_ResName:len () + 1) == g_ResName.."." ) then
		name = name:sub(g_ResName:len() + 2)
	end
	
	if(g_Settings[name] ~= nil and g_PrivateSettings[name] == nil) then
		new_val = fromJSON(new_val)
		g_Settings[name] = nil--new_val
		--outputDebugString("Cached value changed "..name.." "..new_val, 2)
	end
end

addInitFunc(function()
	addEventHandler("onSettingChange", g_Root, SmOnSettingChange)
end)
