--------------
-- Includes --
--------------

#include "..\\include\\serv_verification.lua"

-------------
-- Defines --
-------------

#NITRO_TIME = 20000
#AUTO_NITRO_TIME = 60000
#NITRO_UPGRADE_ID = 1010

---------------------
-- Local variables --
---------------------

local g_Root = getRootElement()
local g_Me = getLocalPlayer()
local g_ResRoot = getResourceRootElement()
local g_NitroAmount = 0
local g_Vehicle = false
local g_NitroActive = false
local g_NitroKey = "up"
local g_TempNitroKey = "up"
local g_AutoNitroTimer = false
local g_LastUpdate = getTickCount()
local g_AddNitro = false

local HAS_NITRO_API = getVersion().sortable >= "1.3.1-9.05174" -- above version with crash-fix
local USE_NITRO_API = HAS_NITRO_API

local g_DebugNitro = false
local g_DbgBuf = {}

-------------------
-- Custom events --
-------------------

addEvent("nitro.onPickUp", true)

---------------------------------
-- Local function declarations --
---------------------------------

local NitStart, NitStop

--------------------------------
-- Local function definitions --
--------------------------------

local function DbgGetTimeStr()
	local tm = getRealTime()
	local ticks = getTickCount()
	return ("[%u:%02u:%02u - 0x%08x] "):format(tm.hour, tm.minute, tm.second, ticks)
end

local function DbgPrint(fmt, ...)
	if(not g_DebugNitro) then return end
	
	if(#g_DbgBuf >= 100) then
		table.remove(g_DbgBuf, 1)
	end
	
	local tm = getRealTime()
	local str = DbgGetTimeStr()..fmt:format(...).."\n"
	table.insert(g_DbgBuf, str)
	
	outputDebugString(fmt:format(...))
end

local function DbgSave()
	local filename = "nitro.log"
	local file = fileExists(filename) and fileOpen(filename) or fileCreate(filename)
	if(file) then
		fileSetPos(file, fileGetSize(file))
		fileWrite(file, table.concat(g_DbgBuf))
		fileWrite(file, DbgGetTimeStr().."BUG!\n")
		g_DbgBuf = {}
		fileClose(file)
	else
		outputDebugString("Failed to open file", 2)
	end
end

local function NitAdd()
	g_NitroAmount = $(NITRO_TIME)
	if(g_Vehicle) then
		local ret = addVehicleUpgrade(g_Vehicle, $(NITRO_UPGRADE_ID))
		DbgPrint("addVehicleUpgrade: "..tostring(ret))
		if(g_NitroKey == "down" or g_TempNitroKey == "down") then
			NitStart()
		else
			NitStop()
		end
	else
		DbgPrint("no vehicle!")
	end
end

local function NitRemove()
	g_NitroAmount = 0
	g_NitroActive = false
	g_AddNitro = false
	if(g_Vehicle) then
		local ret = removeVehicleUpgrade(g_Vehicle, $(NITRO_UPGRADE_ID))
		DbgPrint("removeVehicleUpgrade: "..tostring(ret))
	else
		DbgPrint("no vehicle!")
	end
end

local function NitTimerProc()
	g_AutoNitroTimer = false
	NitAdd()
	DbgPrint("added auto nitro")
end

local function NitStartAutoNitro()
	if(g_AutoNitroTimer) then
		resetTimer(g_AutoNitroTimer)
	else
		g_AutoNitroTimer = setTimer(NitTimerProc, $(AUTO_NITRO_TIME), 1)
	end
end

local function NitStopAutoNitro()
	if(g_AutoNitroTimer) then
		killTimer(g_AutoNitroTimer)
		g_AutoNitroTimer = false
	end
end

function NitStart()
	DbgPrint("NitStart "..g_NitroAmount)
	if(g_NitroAmount > 0) then
		if(not g_NitroActive) then
			NitStartAutoNitro()
		end
		g_NitroActive = true
		if(USE_NITRO_API) then
			setVehicleNitroActivated(g_Vehicle, true)
		else
			--g_AddNitro = false
			-- always set control state because player could change it when using temp nitro
			setControlState("vehicle_fire", true)
		end
	end
end

function NitStop()
	DbgPrint("NitStop "..tostring(g_NitroActive))
	if(not g_NitroActive) then return end
	
	g_NitroActive = false
	if(USE_NITRO_API) then
		setVehicleNitroActivated(g_Vehicle, false)
	else
		setControlState("vehicle_fire", false)
		if(g_Vehicle) then
			removeVehicleUpgrade(g_Vehicle, $(NITRO_UPGRADE_ID))
		end
		g_AddNitro = true -- add nitro in next frame, if it would be added here GTA would not handle setControlState before and nitro would start
	end
end

local function NitCanVehicleUseNitro(veh)
	local t = getVehicleType(veh)
	return (t == "Automobile" or t == "Monster Truck" or t == "Quad")
end

local function NitOnKeyUpDown(key, state)
	DbgPrint("NitOnKeyUpDown")
	g_NitroKey = state
	if(state == "down") then
		NitStart()
	end
end

local function NitOnTempKeyUpDown(key, state)
	DbgPrint("NitOnTempKeyUpDown")
	g_TempNitroKey = state
	if(g_Vehicle) then
		if(state == "up") then
			NitStop()
		elseif(not g_NitroActive and g_NitroAmount > 0) then -- state == "down"
			NitStart()
		end
	end
end

local function NitInit()
	bindKey("vehicle_fire", "both", NitOnKeyUpDown)
	bindKey("vehicle_secondary_fire", "both", NitOnKeyUpDown)
	
	bindKey("mouse2", "both", NitOnTempKeyUpDown)
	
	g_Vehicle = getPedOccupiedVehicle(g_Me)
end

local function NitOnVehicleEnter(player)
	if(player == g_Me) then
		DbgPrint ("NitOnVehicleEnter", 2)
		NitRemove()
		NitStopAutoNitro()
		g_Vehicle = source
	end
end

local function NitOnVehicleExit(player)
	if(player == g_Me) then
		DbgPrint("NitOnVehicleExit")
		NitRemove()
		NitStopAutoNitro()
		g_Vehicle = false
	end
end

local function NitOnPlayerWasted()
	DbgPrint("NitOnPlayerWasted"..(source==g_Me and "" or " wtf"))
	NitRemove()
	NitStopAutoNitro()
	g_Vehicle = false
end

local function NitOnElementDestroy()
	if(source ~= g_Vehicle) then
		return
	end
	
	DbgPrint("NitOnElementDestroy g_Vehicle")
	NitRemove()
	NitStopAutoNitro()
	g_Vehicle = false
end

local function NitOnPickUpNitro ()
	NitAdd()
	DbgPrint("NitOnPickUpNitro")
end

local function NitUpdate()
	if(g_Vehicle) then
	
		-- update nitro based on time change
		local dt = getTickCount() - g_LastUpdate
		if(g_NitroActive) then
			if(dt >= g_NitroAmount) then
				DbgPrint("nitro end")
				NitRemove()
			else
				g_NitroAmount = g_NitroAmount - dt
			end
		end
		
		-- check if vehicle has nitro already
		local upg = getVehicleUpgradeOnSlot(g_Vehicle, 8)
		if(upg > 0) then
			if(g_NitroAmount == 0) then
				NitAdd()
				DbgPrint("added surprise nitro: "..upg)
			end
		elseif(g_NitroAmount > 0 and not g_AddNitro) then
			NitRemove()
			DbgPrint("removed surprise nitro")
		end
		
		-- add delayed nitro, if requested
		if(g_AddNitro and g_NitroAmount > 0) then
			local ret = addVehicleUpgrade(g_Vehicle, $(NITRO_UPGRADE_ID))
			DbgPrint("added delayed nitro: "..tostring(ret))
		end
		
		g_AddNitro = false
	end
	
	g_LastUpdate = getTickCount()
end

local function NitDebug()
	g_DebugNitro = not g_DebugNitro
	if(g_DebugNitro) then
		outputChatBox("Nitro debugging is enabled!", 0, 255, 0)
		DbgPrint("====================")
	else
		outputChatBox("Nitro debugging is disabled!", 255, 0, 0)
	end
end

addCommandHandler("nitrodbg", NitDebug)

local function NitBug()
	if(g_DebugNitro) then
		DbgSave()
		outputChatBox("Saved!", 0, 255, 0)
	end
end

addCommandHandler("nitrobug", NitBug)

local function NitExperimental()
	if(not HAS_NITRO_API) then return end
	
	USE_NITRO_API = not USE_NITRO_API
	if(USE_NITRO_API) then
		outputChatBox("Experimental Nitro is enabled!", 0, 255, 0)
	else
		outputChatBox("Experimental Nitro is disabled!", 255, 0, 0)
	end
end

addCommandHandler("nitro2", NitExperimental)

---------------------------------
-- Global function definitions --
---------------------------------

function getNitro()
	return g_NitroAmount/$(NITRO_TIME)
end

------------
-- Events --
------------

#VERIFY_SERVER_BEGIN("13B8ACB2C0389B52D0EA7DA16B794CBC")
	addEventHandler("onClientVehicleEnter", g_Root, NitOnVehicleEnter)
	addEventHandler("onClientVehicleExit", g_Root, NitOnVehicleExit)
	addEventHandler("onClientPlayerWasted", g_Me, NitOnPlayerWasted)
	addEventHandler("onClientElementDestroy", g_Root, NitOnElementDestroy)
	addEventHandler("onClientPreRender", g_Root, NitUpdate)
	addEventHandler("nitro.onPickUp", g_ResRoot, NitOnPickUpNitro)
	
	NitInit()
#VERIFY_SERVER_END()
