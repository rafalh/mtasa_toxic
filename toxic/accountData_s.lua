AccountData = {}
AccountData.__mt = {__index = AccountData}
AccountData.onChangeHandlers = {}
AccountData.map = {}
setmetatable(AccountData.map, {__mode = "v"}) -- weak table

-- Note: default is always used for guests (even if database would ignore it)
PlayersTable = Database.Table{
	name = "players",
	{"player",         "INT UNSIGNED",       pk = true, default = 0},
	{"serial",         "VARCHAR(32)",        default = ""},
	{"account",        "VARCHAR(255)",       default = "", null = true},
	{"warnings",       "TINYINT UNSIGNED",   default = 0},
	{"time_here",      "INT UNSIGNED",       default = 0},
	{"first_visit",    "INT UNSIGNED",       default = 0},
	{"last_visit",     "INT UNSIGNED",       default = 0},
	{"ip",             "VARCHAR(16)",        default = ""},
	{"name",           "VARCHAR(32)",        default = ""},
	{"online",         "BOOL",               default = 0},
	{"email",          "VARCHAR(128)",       default = ""},
	
	{"players_idx", unique = {"account"}},
}

local DefaultData = false

function AccountData:getTbl()
	local cache = rawget(self, "cache")
	if(not cache) then
		assert(self.id)
		local rows = DbQuery("SELECT * FROM "..PlayersTable.." WHERE player=? LIMIT 1", self.id)
		cache = rows[1] or false
		rawset(self, "cache", cache)
	end
	
	return cache
end

function AccountData:get(name)
	assert(type(self) == "table" and name)
	
	local fields = name
	if(type(fields) ~= "table") then
		fields = {name}
	end
	
	local cache = AccountData.getTbl(self)
	if(not cache) then -- load cache
		return false
	end
	
	local result = {}
	for i, field in ipairs(fields) do
		if(cache[field] ~= nil) then
			result[field] = cache[field]
		else
			outputDebugString("Unknown field "..field, 2)
		end
	end
	
	if(type(name) == "table") then
		return result
	else
		return result[name]
	end
end

-- AccountData:set(tbl, silent)
-- AccountData:set(name, value, silent)
function AccountData:set(arg1, arg2, arg3)
	assert(type(self) == "table" and arg1)
	
	local data, silent
	if(type(arg1) == "table") then
		data = arg1
		silent = arg2
	else
		data = {[arg1] = arg2 or false}
		silent = arg3
	end
	
	local set = ""
	local params = {}
	for k, v in pairs(data) do
		assert(PlayersTable.colMap[k])
		if(not self.cache or self.cache[k] ~= v) then
			if(v == false) then
				set = set..","..k.."=NULL"
			elseif(type(v) == "string" and PlayersTable.colMap[k][2] == "BLOB" and v) then
				set = set..","..k.."="..DbBlob(v)
			else
				set = set..","..k.."=?"
				table.insert(params, v)
			end
			
			if(not silent) then
				for i, handler in ipairs(AccountData.onChangeHandlers) do
					handler(self, k, v)
				end
			end
			
			if(self.cache) then
				self.cache[k] = v
			end
		end
	end
	
	if(self.id and set ~= "") then
		-- Add player ID at the end of parameters table. Note: we can't use it when calling DbQuery
		-- because unpack has to be on the last place. If it's not only one element from table is used.
		table.insert(params, self.id)
		
		return DbQuery("UPDATE "..PlayersTable.." SET "..set:sub(2).." WHERE player=?", unpack(params))
	else
		return true
	end
end

function AccountData:add(name, num)
	assert(type(self) == "table" and name and num)
	local val = AccountData.get(self, name)
	assert(type(val) == "number")
	return AccountData.set(self, name, val + num)
end

local function getDefaultData()
	if(DefaultData) then return DefaultData end
	
	DefaultData = {}
	for i, fieldInfo in ipairs(PlayersTable) do
		if(#fieldInfo >= 2) then
			assert(fieldInfo.default ~= nil)
			DefaultData[fieldInfo[1]] = fieldInfo.default
		end
	end
	return DefaultData
end

function AccountData.create(id)
	if(id and AccountData.map[id]) then
		return AccountData.map[id]
	end
	
	local self = {id = id, cache = false}
	self.lol = true
	if(id) then
		AccountData.map[id] = self
	else
		self.cache = table.copy(getDefaultData())
	end
	
	return setmetatable(self, AccountData.__mt)
end

function AccountData.__mt.__index(self, k)
	local val = AccountData[k] or rawget(self, k)
	if(val ~= nil) then
		return val
	else
		return AccountData.get(self, k)
	end
end

function AccountData.__mt.__newindex(self, k, v)
	--outputDebugString("__newindex "..tostring(k), 3)
	AccountData.set(self, k, v)
end

local function init()
	
end

init() -- Do it now (don't use addInitFunc)
