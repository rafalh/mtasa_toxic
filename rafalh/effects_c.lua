--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------
-- Variables --
---------------

g_Effects = {}
g_EffectsCount = 0
local g_LowFpsSeconds = 0

-------------------
-- Custom events --
-------------------

addEvent("onRafalhAddEffect")
addEvent("onRafalhGetEffects")

--------------------------------
-- Local function definitions --
--------------------------------

local function checkFps()
	-- Note: it needs scorefps resource
	local fps = tonumber(getElementData(g_Me, "fps"))
	if(not fps) then return end
	
	-- If FPS < 25 disable effects
	if(fps >= 25) then
		g_LowFpsSeconds = 0
		return
	end
	
	-- LOW FPS
	g_LowFpsSeconds = g_LowFpsSeconds + 1
	
	-- Allow low FPS for 20 seconds
	if(g_LowFpsSeconds < 20) then return end
	
	for res, name in pairs(g_Effects) do
		local enabled = call(res, "isEffectEnabled")
		if(enabled) then
			-- disable first enabled effect
			call(res, "setEffectEnabled", false)
			
			-- count from 0
			g_LowFpsSeconds = 0
			
			-- display message for user
			if(type(name) == "table") then
				name = name[g_ClientSettings.locale] or name[1]
			end
			if(name) then
				outputChatBox(MuiGetMsg("%s has been disabled to improve your FPS!"):format(name), 255, 0, 0)
			end
			
			break
		end
	end
end

local function onClientThisResourceStart()
	-- Get all effects on startup
	triggerEvent("onRafalhGetEffects", g_Root)
	
	-- Check if FPS is not too low
	setTimer(checkFps, 1000, 0)
end

local function onClientResourceStop(res)
	if(not g_Effects[res]) then return end
	
	-- Effect has been stoped
	g_Effects[res] = nil
	g_EffectsCount = g_EffectsCount - 1
	
	-- Effects list has changed
	invalidateSettingsGui()
end

local function onAddEffect(res, name)
	assert(res)
	
	-- Register effect resource
	if(not g_Effects[res]) then
		g_EffectsCount = g_EffectsCount + 1
	end
	g_Effects[res] = name
	
	-- Apply effect settings
	local res_name = getResourceName(res)
	local effect_enabled = g_ClientSettings.effects[res_name]
	if(effect_enabled ~= nil) then
		call(res, "setEffectEnabled", effect_enabled)
	end
	
	-- Effects list has changed
	invalidateSettingsGui()
end

------------
-- Events --
------------

addEventHandler("onClientResourceStart", g_ResRoot, onClientThisResourceStart)
addEventHandler("onClientResourceStop", g_Root, onClientResourceStop)
addEventHandler("onRafalhAddEffect", g_Root, onAddEffect)
