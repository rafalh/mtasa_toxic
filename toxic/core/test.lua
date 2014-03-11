namespace('Test')

local g_Map = {}
local g_FailCount = 0
local g_ExecutedCount = 0
local g_Player

local function outputMsg(msg)
	if(getElementType(g_Player) == 'console') then
		outputServerLog('TEST: '..msg)
	elseif(g_ServerSide) then
		outputChatBox(msg, g_Player, 255, 255, 255)
	else
		outputChatBox(msg, 255, 255, 255)
	end
end

function register(name, func)
	g_Map[name] = func
end

function check(cond, descr, offset)
	g_ExecutedCount = g_ExecutedCount + 1
	if(cond) then return end
	
	g_FailCount = g_FailCount + 1
	local trace = Debug.getStackTrace(1, (offset or 0) + 1)
	outputMsg('Test failed - '..(descr or tostring(cond))..' in '..trace[1])
end

function checkEq(val, validVal, descr)
	check(val == validVal, 'expected '..tostring(validVal)..', got '..tostring(val)..(descr and ' '..descr or ''), 1)
end

function checkGt(val1, val2, descr)
	check(val1 > val2, 'expected '..tostring(val1)..' > '..tostring(val2)..(descr and ' '..descr or ''), 1)
end

function checkGte(val1, val2, descr)
	check(val1 >= val2, 'expected '..tostring(val1)..' >= '..tostring(val2)..(descr and ' '..descr or ''), 1)
end

function checkLt(val1, val2, descr)
	check(val1 < val2, 'expected '..tostring(val1)..' < '..tostring(val2)..(descr and ' '..descr or ''), 1)
end

function checkLte(val1, val2, descr)
	check(val1 <= val2, 'expected '..tostring(val1)..' <= '..tostring(val2)..(descr and ' '..descr or ''), 1)
end

function checkTblEq(tbl, validTbl, descr)
	check(type(tbl) == 'table' and type(validTbl) == 'table' and table.compare(tbl, validTbl, true), 'expected '..table.dump(validTbl)..', got '..table.dump(tbl), 1)
end

local function runInternal(name)
	local prof = DbgPerf(5)
	local f = g_Map[name]
	local status, err = pcall(f)
	if(not status) then
		Test.check(false, tostring(err), 1)
	end
	prof:cp('test \''..name..'\'')
end

function run(name, player)
	g_FailCount, g_ExecutedCount = 0, 0
	g_Player = player
	if(name) then
		runInternal(name)
	else
		for name, f in pairs(g_Map) do
			outputMsg('Starting test \''..name..'\'')
			runInternal(name)
		end
	end
	
	outputMsg(g_ExecutedCount..' tests executed - '..g_FailCount..' tests failed')
end

if(g_ServerSide) then
	addCommandHandler('tests', function(player, cmd, testName)
		if(isPlayerAdmin(player)) then
			run(testName, player)
		end
	end, false, true)
else
	addCommandHandler('testc', function(cmd, testName)
		run(testName, localPlayer)
	end, true)
end
