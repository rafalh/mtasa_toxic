--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

---------------
-- Variables --
---------------

local g_Effects = {}
local g_Enabled = {}
local g_LowFpsSeconds = 0

-------------------
-- Custom events --
-------------------

addEvent('onRafalhAddEffect')
addEvent('onRafalhGetEffects')
addEvent('toxic.onEffectInfo')
addEvent('toxic.onEffectInfoReq')

--------------------------------
-- Local function definitions --
--------------------------------

local function checkFps()
	-- Note: it needs scorefps resource
	local fps = tonumber(getElementData(g_Me, 'fps'))
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
	
	for res, info in pairs(g_Effects) do
		local enabled = call(res, 'isEffectEnabled')
		if(enabled) then
			-- disable first enabled effect
			call(res, 'setEffectEnabled', false)
			
			-- count from 0
			g_LowFpsSeconds = 0
			
			-- display message for user
			local name = info.name
			if(type(name) == 'table') then
				name = name[Settings.locale] or name[1]
			end
			if(name) then
				outputMsg(Styles.red, "%s has been disabled to improve your FPS!", name)
			end
			
			break
		end
	end
end

local function onResStop(res)
	if(not g_Effects[res]) then return end
	
	-- Effect has been stoped
	g_Effects[res] = nil
	
	-- Effects list has changed
	invalidateSettingsGui()
end

local function onEffectInfo(info)
	-- Check parameters
	assert(info and info.name and info.res)
	
	-- Register effect resource
	g_Effects[info.res] = info
	
	-- Apply effect settings
	local resName = getResourceName(info.res)
	local enabled = g_Enabled[resName]
	if(enabled ~= nil) then
		call(info.res, 'setEffectEnabled', enabled)
	end
	
	-- Effects list has changed
	invalidateSettingsGui()
end

local function onAddEffect(res, name)
	-- Old API
	local info = {name = name, res = res}
	onEffectInfo(info)
end

local function init()
	addEventHandler('onClientResourceStop', g_Root, onResStop)
	addEventHandler('onRafalhAddEffect', g_Root, onAddEffect)
	addEventHandler('toxic.onEffectInfo', g_Root, onEffectInfo)

	-- Get all effects on startup
	triggerEvent('onRafalhGetEffects', g_Root)
	triggerEvent('toxic.onEffectInfoReq', g_Root)
	
	-- Check if FPS is not too low
	setTimer(checkFps, 1000, 0)
end

local EffectSettings =
{
	name = 'effects',
	default = '',
	priority = 1000,
	cast = tostring,
	onChange = function(oldVal, newVal)
		g_Enabled = fromJSON(newVal)
		for res, enabled in pairs(g_Enabled) do
			local res = getResourceFromName(res)
			if(res and g_Effects[res]) then
				call(res, 'setEffectEnabled', tobool(enabled))
			end
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		guiCreateLabel(x, y + 5, w, 20, "Effects:", false, wnd)
		local h, gui = 25, {}
		
		local function onBtnToggle()
			onChange('effects')
		end
		
		for res, info in pairs(g_Effects) do
			local enabled = call(res, 'isEffectEnabled')
			local name = info.name
			if(type(name) == 'table') then
				name = name[Settings.locale] or name[1]
			end
			if(name) then
				guiCreateLabel(x, y + h, 200, 20, name, false, wnd)
				gui[res] = OnOffBtn.create(x + 200, y + h, wnd, enabled)
				gui[res].onChange = onBtnToggle
				
				if(info.hasOptions) then
					local optsBtn = guiCreateButton(x + 200 + OnOffBtn.w + 5, y + h, 60, OnOffBtn.h, "Options", false, wnd)
					addEventHandler('onClientGUIClick', optsBtn, function()
						call(res, 'openEffectOptions')
					end, false)
				end
				
				h = h + 25
			end
		end
		
		return h, gui
	end,
	acceptGui = function(gui)
		for res, btn in pairs(gui) do
			if(g_Effects[res]) then
				local resName = getResourceName(res)
				g_Enabled[resName] = btn:isEnabled()
			end
		end
		Settings.effects = toJSON(g_Enabled)
	end,
}

addInitFunc(init)
addInitFunc(function()
	Settings.register(EffectSettings, -2000)
end, -2000)
