--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------
-- Variables --
---------------

local g_Effects = {}
local g_Enabled = {}
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
				name = name[Settings.locale] or name[1]
			end
			if(name) then
				outputChatBox(MuiGetMsg("%s has been disabled to improve your FPS!"):format(name), 255, 0, 0)
			end
			
			break
		end
	end
end

local function init()
	-- Get all effects on startup
	triggerEvent("onRafalhGetEffects", g_Root)
	
	-- Check if FPS is not too low
	setTimer(checkFps, 1000, 0)
end

local function onResStop(res)
	if(not g_Effects[res]) then return end
	
	-- Effect has been stoped
	g_Effects[res] = nil
	
	-- Effects list has changed
	invalidateSettingsGui()
end

local function onAddEffect(res, name)
	assert(res)
	
	-- Register effect resource
	g_Effects[res] = name
	
	-- Apply effect settings
	local resName = getResourceName(res)
	local enabled = g_Enabled[resName]
	if(enabled ~= nil) then
		call(res, "setEffectEnabled", enabled)
	end
	
	-- Effects list has changed
	invalidateSettingsGui()
end

Settings.register
{
	name = "effects",
	default = "",
	priority = 1000,
	cast = tostring,
	onChange = function(oldVal, newVal)
		g_Enabled = fromJSON(newVal)
		for res, enabled in pairs(g_Enabled) do
			local res = getResourceFromName(res)
			if(res) then
				call(res, "setEffectEnabled", tobool(enabled))
			end
		end
	end,
	createGui = function(wnd, x, y, w)
		guiCreateLabel(x, y + 5, w, 20, "Effects:", false, wnd)
		local h, gui = 25, {}
		
		for res, name in pairs(g_Effects) do
			local enabled = call(res, "isEffectEnabled")
			if(type(name) == "table") then
				name = name[Settings.locale] or name[1]
			end
			if(name) then
				guiCreateLabel(x, y + h, 200, 20, name, false, wnd)
				gui[res] = OnOffBtn.create(x + 200, y + h, wnd, enabled)
				
				--gui[res] = guiCreateButton(x + 200, y + h, 60, 20, "ON", false, wnd)
				--guiSetProperty(gui[res], "NormalTextColour", "FF00FF00")
				
				--gui[res] = guiCreateCheckBox(x, y + h, w, 20, name, enabled, false, wnd)
				h = h + 25
			end
		end
		
		return h, gui
	end,
	acceptGui = function(gui)
		for res, btn in pairs(gui) do
			local enabled = btn.enabled -- guiCheckBoxGetSelected(cb)
			if(g_Effects[res]) then
				local resName = getResourceName(res)
				g_Enabled[resName] = enabled
			end
		end
		Settings.effects = toJSON(g_Enabled)
	end,
}

------------
-- Events --
------------

addEventHandler("onClientResourceStart", g_ResRoot, init)
addEventHandler("onClientResourceStop", g_Root, onResStop)
addEventHandler("onRafalhAddEffect", g_Root, onAddEffect)
