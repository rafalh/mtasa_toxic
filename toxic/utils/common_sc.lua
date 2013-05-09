g_Root = getRootElement()
g_ResRoot = getResourceRootElement()
g_Res = getThisResource()
g_ResName = getResourceName(g_Res)

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
	return (var and tostring(var)) or ""
end

function tobool(val, def)
	val = tostring(val):lower()
	if(val == "true" or val == "1") then return true
	elseif(val == "false" or val == "0") then return false
	else return def end
end

function table.size(t)
	local n = 0
	
	for i, v in pairs(t) do
		n = n + 1
	end
	
	return n
end

function table.empty(tbl)
	return (next(tbl) == nil)
end

function table.find(tbl, v)
	for i, val in ipairs(tbl) do
		if(val == v) then
			return i
		end
	end
	
	return false
end

function table.copy(tbl, full)
	local ret = {}
	for k, v in pairs(tbl) do
		if(type(v) == "table" and full) then
			ret[k] = table.copy(v)
		else
			ret[k] = v
		end
	end
	return ret
end

function table.removeValue(tbl, v)
	local i = table.find(tbl, v)
	if(i) then table.remove(tbl, i) end
end

function formatDate(timestamp)
	local tm = getRealTime(timestamp)
	return ("%d-%02d-%02d %d:%02d"):format(tm.monthday, tm.month + 1, tm.year + 1900, tm.hour, tm.minute)
end

function formatTimePeriod(t, decimals)
	assert(t)
	
	local h = math.floor(t / 3600)
	local m = math.floor((t % 3600) / 60)
	local s = math.floor(t % 60)
	local str = (h > 0 and h..":%02u:%02u" or "%u:%02u"):format(m, s)
	
	local dec = touint(decimals, 2)
	if(dec > 0) then
		local rest = math.floor((t % 1)*(10^dec))
		str = str..(".%0"..dec.."u"):format(rest)
	end
	
	return str
end

function formatNumber(num, decimals)
	num = tonumber(num)
	assert(num)
	local n1, n2 = math.modf(num)
	n1 = tostring(n1)
	local buf = ""
	
	while(n1 ~= "") do
		buf = n1:sub(-3).." "..buf
		n1 = n1:sub(1, -4)
	end
	buf = buf:sub(1, -2)
	if(decimals) then
		return buf.."."..(n2..("0"):rep(decimals)):sub(1, decimals)
	end
	return buf
end

function formatMoney(money)
	assert(money)
	local str = tostring(math.floor(math.abs(money)))
	local buf = ""
	
	while(str ~= "") do
		buf = str:sub ( -3 )..","..buf
		str = str:sub ( 1, -4 )
	end
	return ((tonumber ( money ) < 0 and "-") or "")..buf:sub(1, -2).." €"
end

local _isPedDead = isPedDead
function isPedDead(player)
	if(Player and Player.fromEl(player) and Player.fromEl(player).is_console) then
		return false -- console
	end
	local state = getElementData(player, "state")
	if(state and state ~= "alive") then
		return true
	end
	return(state and state ~= "alive") or _isPedDead (player)
end

function isPlayerAdmin(player)
	local adminGroup = aclGetGroup("Admin")
	local account = getPlayerAccount(player)
	local accountName = getAccountName(account)
	return (adminGroup and account and isObjectInACLGroup("user."..accountName, adminGroup))
end

local function fileCopy(srcPath, dstPath)
	local success = false
	local dstFile = fileCreate(dstPath)
	if(dstFile) then
		local srcFile = fileOpen(srcPath, true)
		if(srcFile) then
			while(not fileIsEOF(srcFile)) do
				local buf = fileRead(srcFile, 4096)
				fileWrite(dstFile, buf)
			end
			success = true
			fileClose(srcFile)
		end
		
		fileClose(dstFile)
	end
	
	return success
end
