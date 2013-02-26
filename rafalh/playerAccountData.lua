PlayerAccountData = {}
PlayerAccountData.__mt = {__index = PlayerAccountData}
PlayerAccountData.onChangeHandlers = {}
PlayerAccountData.map = {}
setmetatable(PlayerAccountData.map, {__mode = "v"}) -- weak table

local AccountDataFields = {
--   name              type           flags                 default value
	{"player",         "INTEGER",     "PRIMARY KEY AUTOINCREMENT NOT NULL", 0},
	{"serial",         "VARCHAR(32)", "NOT NULL",             ""},
	{"account",        "TEXT",        "UNIQUE",               ""},
	{"cash",           "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"points",         "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"warnings",       "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"dm",             "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"dm_wins",        "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"first",          "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"second",         "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"third",          "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"time_here",      "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"first_visit",    "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"last_visit",     "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"bidlvl",         "INTEGER",     "DEFAULT 1 NOT NULL",   1},
	{"ip",             "VARCHAR(16)", "DEFAULT '' NOT NULL",  ""},
	{"name",           "VARCHAR(32)", "DEFAULT '' NOT NULL",  ""},
	{"joinmsg",        "VARCHAR(128)", "DEFAULT NULL",        false},
	{"pmuted",         "BOOL",        "DEFAULT 0 NOT NULL",   0},
	{"toptimes_count", "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"online",         "BOOL",        "DEFAULT 0 NOT NULL",   0},
	{"exploded",       "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"drowned",        "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"locked_nick",    "BOOL",        "DEFAULT 0 NOT NULL",   0},
	{"invitedby",      "INTEGER",     "DEFAULT 0 NOT NULL",   0},
	{"achievements",   "BLOB",        "DEFAULT x'' NOT NULL", ""},
	{"mapBoughtTimestamp", "INTEGER", "DEFAULT 0 NOT NULL",   0},
	{"email",          "VARCHAR(128)", "DEFAULT '' NOT NULL", ""},
	
	-- New stats
	{"maxWinStreak",  "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"mapsPlayed",    "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"mapsBought",    "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"mapsRated",     "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"huntersTaken",  "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"dmVictories",   "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"ddVictories",   "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"raceVictories", "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"racesFinished", "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"dmPlayed",      "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"ddPlayed",      "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"racesPlayed",   "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"achvCount",     "INTEGER", "DEFAULT 0 NOT NULL", 0},
	
	-- Shop
	{"health100",    "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"selfdestr",    "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"mines",        "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"oil",          "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"beers",        "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"invisibility", "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"godmodes30",   "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"flips",        "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"thunders",     "INTEGER", "DEFAULT 0 NOT NULL", 0},
	{"smoke",        "INTEGER", "DEFAULT 0 NOT NULL", 0},
	
	-- Effectiveness
	{"efectiveness",      "REAL", "DEFAULT 0 NOT NULL", 0},
	{"efectiveness_dd",   "REAL", "DEFAULT 0 NOT NULL", 0},
	{"efectiveness_dm",   "REAL", "DEFAULT 0 NOT NULL", 0},
	{"efectiveness_race", "REAL", "DEFAULT 0 NOT NULL", 0}
}
local DefaultData = {}
local FieldsMap = {}

function PlayerAccountData:getTbl()
	if(not self.cache) then
		assert(self.id)
		local rows = DbQuery("SELECT * FROM rafalh_players WHERE player=? LIMIT 1", self.id)
		self.cache = rows[1]
	end
	
	return self.cache
end

function PlayerAccountData:get(name)
	assert(type(self) == "table" and name)
	
	local fields = name
	if(type(fields) ~= "table") then
		fields = {name}
	end
	
	self:getTbl() -- load cache
	
	local result = {}
	for i, field in ipairs(fields) do
		if(self.cache[field] ~= nil) then
			result[field] = self.cache[field]
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

function PlayerAccountData:set(name, value, silent)
	assert(type(self) == "table" and name)
	
	local data = name
	if(type(data) ~= "table") then
		data = {[name] = value or false}
	end
	
	local set = ""
	local params = {}
	for k, v in pairs(data) do
		assert(FieldsMap[k])
		if(not self.cache or self.cache[k] ~= v) then
			if(v == false) then
				set = set..","..k.."=NULL"
			elseif(type(v) == "string" and FieldsMap[k][2] == "BLOB" and v) then
				set = set..","..k.."="..DbBlob(v)
			else
				set = set..","..k.."=?"
				table.insert(params, v)
			end
			
			if(not silent) then
				for i, handler in ipairs(PlayerAccountData.onChangeHandlers) do
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
		
		return DbQuery("UPDATE rafalh_players SET "..set:sub(2).." WHERE player=?", unpack(params))
	else
		return true
	end
end

function PlayerAccountData:add(name, num)
	assert(type(self) == "table" and name and num)
	local val = self:get(name)
	assert(type(val) == "number")
	return self:set(name, val + num)
end

function PlayerAccountData.create(id)
	if(id and PlayerAccountData.map[id]) then
		return PlayerAccountData.map[id]
	end
	
	local self = {id = id, cache = false}
	setmetatable(self, PlayerAccountData.__mt)
	if(id) then
		PlayerAccountData.map[id] = self
	else
		self.cache = table.copy(DefaultData)
	end
	return self
end

function PlayerAccountData.__mt.__index(self, k)
	--outputDebugString("__index "..tostring(k), 3)
	if(PlayerAccountData[k]) then
		return PlayerAccountData[k]
	else
		return PlayerAccountData.get(self, k)
	end
end

function PlayerAccountData.__mt.__newindex(self, k, v)
	--outputDebugString("__newindex "..tostring(k), 3)
	PlayerAccountData.set(self, k, v)
end

local function init()
	for i, fieldInfo in ipairs(AccountDataFields) do
		DefaultData[fieldInfo[1]] = fieldInfo[4]
		FieldsMap[fieldInfo[1]] = fieldInfo
	end
end

function PlayerAccountData.getDbTableFields()
	local fields = {}
	for i, fieldInfo in ipairs(AccountDataFields) do
		table.insert(fields, fieldInfo[1].." "..fieldInfo[2].." "..fieldInfo[3])
	end
	return table.concat(fields, ", ")
end

init()
