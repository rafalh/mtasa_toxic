LocaleList = {}
LocaleList.tbl = false

function LocaleList.addLocale(locale)
	if(LocaleList.tbl[locale.code]) then return end
	
	LocaleList.tbl[locale.code] = locale
	table.insert(LocaleList.tbl, locale)
end

function LocaleList.init()
	LocaleList.tbl = {}
	
	local defLocale = {code = 'en', name = "English", img = 'img/flags/en.png'}
	LocaleList.addLocale(defLocale)
	
	local node = xmlLoadFile('conf/languages.xml')
	if(node) then
		for i, subnode in ipairs(xmlNodeGetChildren(node)) do
			local locale = {}
			locale.code = xmlNodeGetValue(subnode)
			locale.name = xmlNodeGetAttribute(subnode, 'name') or locale.code
			locale.img = xmlNodeGetAttribute(subnode, 'img')
			if(locale.code) then
				LocaleList.addLocale(locale)
			end
		end
		xmlUnloadFile(node)
	end
end

function LocaleList.get(code)
	if(not LocaleList.tbl) then
		LocaleList.init()
	end
	
	return LocaleList.tbl[code]
end

function LocaleList.exists(code)
	return LocaleList.get(code) and true
end

function LocaleList.ipairs()
	if(not LocaleList.tbl) then
		LocaleList.init()
	end
	
	return ipairs(LocaleList.tbl)
end

function LocaleList.count()
	if(not LocaleList.tbl) then
		LocaleList.init()
	end
	
	return #LocaleList.tbl
end

addInitFunc(LocaleList.init, -1)
