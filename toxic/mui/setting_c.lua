local g_LangButtons, g_NewLocale

local function onFlagClick()
	local lang = g_LangButtons[source]
	g_NewLocale = lang
	for img, lang in pairs(g_LangButtons) do
		guiSetAlpha(img, lang == g_NewLocale and 1 or 0.3)
	end
end

Settings.register
{
	name = 'locale',
	default = 'en',
	priority = 0,
	cast = tostring,
	onChange = function(oldVal, newVal)
		if(g_Ready) then
			triggerServerEvent('main.onSetLocaleReq', g_ResRoot, newVal)
		end
	end,
	createGui = function(wnd, x, y, w, onChange)
		guiCreateLabel(x, y, w, 15, "Language:", false, wnd)
		
		local flagSpace = 5
		local flagW = math.min(50, (w + flagSpace - 20) / LocaleList.count() - flagSpace) -- -20 because scrollPane looks bad
		local flagH = math.floor(flagW * 2 / 3)
		local gui = {}
		
		-- Reset global variables
		g_LangButtons = {}
		g_NewLocale = false
		
		for i, locale in LocaleList.ipairs() do
			local img = guiCreateStaticImage(x, y + 20, flagW, flagH, locale.img, false, wnd)
			setElementData(img, 'tooltip', locale.name)
			addEventHandler('onClientGUIClick', img, onFlagClick, false)
			if(onChange) then
				addEventHandler('onClientGUIClick', img, onChange, false)
			end
			g_LangButtons[img] = locale.code
			
			if(locale.code ~= Settings.locale) then
				guiSetAlpha(img, 0.3)
			end
			
			x = x + flagW + flagSpace
		end
		
		local h = 20 + flagH + 5
		return h, gui
	end,
	acceptGui = function(gui)
		if(g_NewLocale) then
			Settings.locale = g_NewLocale
			g_NewLocale = false
		end
	end,
}
