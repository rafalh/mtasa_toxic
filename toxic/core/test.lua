namespace('Test')

local g_Map = {}
local g_FailCount = 0
local g_ExecutedCount = 0

function register(name, func)
	g_Map[name] = func
end

function check(cond, descr, offset)
	g_ExecutedCount = g_ExecutedCount + 1
	if(cond) then return end
	
	g_FailCount = g_FailCount + 1
	local trace = Debug.getStackTrace(1, offset)
	Debug.err('Test failed: '..(descr or tostring(cond))..' in '..trace[1])
end

function checkEq(val, validVal, descr)
	check(val == validVal, 'expected '..validVal..', got '..val..(descr and ' '..descr or ''), 1)
end

function checkGt(val1, val2, descr)
	check(val1 > val2, 'expected '..val1..' > '..val2..(descr and ' '..descr or ''), 1)
end

function checkGte(val1, val2, descr)
	check(val1 >= val2, 'expected '..val1..' >= '..val2..(descr and ' '..descr or ''), 1)
end

function checkLt(val1, val2, descr)
	check(val1 < val2, 'expected '..val1..' < '..val2..(descr and ' '..descr or ''), 1)
end

function checkLte(val1, val2, descr)
	check(val1 <= val2, 'expected '..val1..' <= '..val2..(descr and ' '..descr or ''), 1)
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

function run(name)
	g_FailCount, g_ExecutedCount = 0, 0
	if(name) then
		runInternal(name)
	else
		for name, f in pairs(g_Map) do
			Debug.info('Starting test: '..name)
			runInternal(name)
		end
	end
	
	Debug.info(g_ExecutedCount..' tests executed - '..g_FailCount..' tests failed')
end

if(g_ServerSide) then
	addCommandHandler('txtests', function(player, cmd, testName)
		run(testName)
	end, false, true)
else
	addCommandHandler('txtestc', function(cmd, testName)
		run(testName)
	end, true)
end
