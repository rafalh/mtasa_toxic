g_Root = getRootElement()
g_ResRoot = getResourceRootElement()
g_Res = getThisResource()
g_ResName = getResourceName(g_Res)
g_ServerSide = triggerClientEvent and true
g_ClientSide = triggerServerEvent and true

function ifElse(condition, trueReturn, falseReturn)
	if(condition) then
		return trueReturn
	end
	return falseReturn
end

function toint(var, nan_r)
	local r = var and tonumber(var)
	return (r and r < math.huge and r > -math.huge and math.floor(r)) or nan_r  -- nan ~= nan
end

function touint(var, nan_r)
	local r = var and tonumber(var)
	return (r and r < math.huge and r > -math.huge and r >= 0 and math.floor(r)) or nan_r -- nan ~= nan
end

function tofloat(var, nan_r)
	local r = var and tonumber(var)
	return (r and r < math.huge and r > -math.huge and r) or nan_r -- nan ~= nan
end

function tonum(var)
	return (var and tonumber(var)) or 0
end

function tostr(var)
	return (var and tostring(var)) or ''
end

function tobool(val, def)
	val = tostring(val):lower()
	if(val == 'true' or val == '1') then return true
	elseif(val == 'false' or val == '0') then return false
	else return def end
end

function math.sign(val)
	if(val > 0) then return 1
	elseif(val < 0) then return -1
	else return 0 end
end

function formatDate(timestamp)
	local tm = getRealTime(timestamp)
	return ('%d-%02d-%02d %d:%02d'):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute)
end

function formatTimePeriod(t, decimals)
	assert(t)
	
	local h = math.floor(t / 3600)
	local m = math.floor((t % 3600) / 60)
	local s = math.floor(t % 60)
	local str = (h > 0 and h..':%02u:%02u' or '%u:%02u'):format(m, s)
	
	local dec = touint(decimals, 2)
	if(dec > 0) then
		local rest = math.floor((t % 1)*(10^dec))
		str = str..('.%0'..dec..'u'):format(rest)
	end
	
	return str
end

function formatNumber(num, decimals)
	num = tonumber(num)
	assert(num)
	local n1, n2 = math.modf(num)
	n1 = tostring(n1)
	local buf = ''
	
	while(n1 ~= '') do
		buf = n1:sub(-3)..' '..buf
		n1 = n1:sub(1, -4)
	end
	buf = buf:sub(1, -2)
	if(decimals) then
		return buf..'.'..(n2..('0'):rep(decimals)):sub(1, decimals)
	end
	return buf
end

function formatMoney(money)
	assert(money)
	local str = tostring(math.floor(math.abs(money)))
	local buf = ''
	
	while(str ~= '') do
		buf = str:sub ( -3 )..','..buf
		str = str:sub ( 1, -4 )
	end
	return ((tonumber ( money ) < 0 and '-') or '')..buf:sub(1, -2)..' €'
end

local _isPedDead = isPedDead
function isPedDead(player)
	-- Check if this is a Console
	if(Player and Player.fromEl(player) and Player.fromEl(player).is_console) then
		return true -- always dead
	end
	
	-- Check state from Race gamemode
	local state = getElementData(player, 'state')
	if(state and state ~= 'alive') then
		return true
	end
	
	-- Call MTA function
	return _isPedDead(player)
end

function isNativeFunction(func)
	local info = debug.getinfo(func, 'S')
	return info.what == 'C'
end

function generateRandomStr(len)
	local chars = {}
	for i = 1, len do
		table.insert(chars, string.char(math.random(0, 255)))
	end
	return table.concat(chars)
end

function namespace(name)
	local components = split(name, '.')
	local ref = _G
	for i, comp in ipairs(components) do
		if (not ref[comp]) then
			ref[comp] = {}
			setmetatable(ref[comp], {__index = _G})
		end
		ref = ref[comp]
	end
	
	setfenv(2, ref)
	return ref
end

-- Simple test
#if(TEST) then
addInitFunc(function()
	Test.register('namespace', function()
		(function()
			namespace('abc')
			x = 1
			namespace('def')
			x = 2
		end)()
		
		Test.checkEq(abc.x, 1)
		Test.checkEq(def.x, 2)
		--Test.checkEq(abc.outputChatBox, nil)
	end)
end)
#end
