AccountData = {}
AccountData.__mt = {__index = AccountData}
AccountData.onChangeHandlers = {}
AccountData.onChangeDoneHandlers = {}
AccountData.map = {}
setmetatable(AccountData.map, {__mode = 'v'}) -- weak table

-- Note: default is always used for guests (even if database would ignore it)
PlayersTable = Database.Table{
	name = 'players',
	{'player',         'INT UNSIGNED',       pk = true, default = 0},
	{'serial',         'VARCHAR(32)',        default = ''},
	{'account',        'VARCHAR(255)',       default = '', null = true},
	{'time_here',      'INT UNSIGNED',       default = 0},
	{'first_visit',    'INT UNSIGNED',       default = 0},
	{'last_visit',     'INT UNSIGNED',       default = 0},
	{'ip',             'VARCHAR(16)',        default = ''},
	{'name',           'VARCHAR(32)',        default = ''},
	{'online',         'BOOL',               default = 0},
	{'email',          'VARCHAR(128)',       default = ''},
	
	{'players_idx', unique = {'account'}},
}

local DefaultData = false

function AccountData:fillCache()
	assert(self.id)
	local rows = DbQuery('SELECT * FROM '..PlayersTable..' WHERE player=? LIMIT 1', self.id)
	cache = rows[1] or false
	self.cache = cache
	self.allCached = true
end

function AccountData:getTbl()
	if(not self.allCached) then
		self:fillCache()
	end
	
	return self.cache
end

function AccountData:get(name)
	assert(type(self) == 'table' and name)
	
	-- prepare arguments
	local fields = name
	if(type(fields) ~= 'table') then
		fields = {name}
	end
	
	local result = {}
	for i, field in ipairs(fields) do
		-- Check if field value is in cache
		if(self.cache[field] == nil) then
			-- Load entire row from database
			self:fillCache()
		end
		
		-- Get value from cache
		local value = self.cache[field]
		if(value ~= nil) then
			result[field] = value
		else
			outputDebugString('Unknown field '..field, 2)
		end
	end
	
	-- Return result in proper format
	if(type(name) == 'table') then
		return result
	else
		return result[name]
	end
end

-- AccountData:set(tbl, silent)
-- AccountData:set(name, value, silent)
function AccountData:set(arg1, arg2, arg3)
	assert(type(self) == 'table' and arg1)
	
	local data, silent
	if(type(arg1) == 'table') then
		data = arg1
		silent = arg2
	else
		data = {[arg1] = arg2 or false}
		silent = arg3
	end
	
	local set = ''
	local params = {}
	for k, v in pairs(data) do
		local colDef = PlayersTable.colMap[k]
		assert(colDef)
		
		if(self.cache[k] == nil or self.cache[k] ~= v) then
			if(v == false) then
				set = set..','..k..'=NULL'
			elseif(type(v) == 'string' and colDef[2] == 'BLOB' and v) then
				set = set..','..k..'='..DbBlob(v)
			else
				set = set..','..k..'=?'
				table.insert(params, v)
			end
			
			if(not silent) then
				for i, handler in ipairs(AccountData.onChangeHandlers) do
					handler(self, k, v)
				end
				--onPostChangeHandlers
			end
			
			self.cache[k] = v
		end
	end
	
	local result = true
	if(self.id and set ~= '') then
		-- Add player ID at the end of parameters table. Note: we can't use it when calling DbQuery
		-- because unpack has to be on the last place. If it's not only one element from table is used.
		table.insert(params, self.id)
		
		result = DbQuery('UPDATE '..PlayersTable..' SET '..set:sub(2)..' WHERE player=?', unpack(params))
	end
	
	if(not silent) then
		for k, v in pairs(data) do
			for i, handler in ipairs(AccountData.onChangeDoneHandlers) do
				handler(self, k)
			end
		end
	end
	
	return result
end

function AccountData:add(name, num)
	assert(type(self) == 'table' and name and num)
	local val = AccountData.get(self, name)
	assert(type(val) == 'number')
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
	
	local self = {id = id, cache = {}, allCached = false}
	if(id) then
		AccountData.map[id] = self
	else
		self.cache = table.copy(getDefaultData())
		self.allCached = true
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
	--outputDebugString('__newindex '..tostring(k), 3)
	AccountData.set(self, k, v)
end
