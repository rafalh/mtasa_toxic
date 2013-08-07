--------------
-- Includes --
--------------

#include 'include/internal_events.lua'

---------------------
-- Local variables --
---------------------

local g_Timer = nil
local g_Stats = {}

local StatsPanel = {
	name = "Statistics",
	img = 'stats/img/icon.png',
	tooltip = "Check your statistics",
	width = 230,
	height = 270,
}

--------------------------------
-- Local function definitions --
--------------------------------

local STATS = {
	{"Cash:", function(stats)
		return formatMoney(stats.cash)
	end},
	{"Points:", function(stats)
		return formatNumber(stats.points)
	end},
	{"Rank:", '_rank'},
	{"DM Victories:", function(stats)
		local dmVictRate = stats.dmVictories / math.max(stats.dmPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.dmVictories), formatNumber(stats.dmPlayed), dmVictRate)
	end},
	{"Hunters taken:", function(stats)
		local huntRate = stats.huntersTaken / math.max(stats.dmPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.huntersTaken), formatNumber(stats.dmPlayed), huntRate)
	end},
	{"DD Victories:", function(stats)
		local ddVictRate = stats.ddVictories / math.max(stats.ddPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.ddVictories), formatNumber(stats.ddPlayed), ddVictRate)
	end},
	{"Race Victories:", function(stats)
		local raceVictRate = stats.raceVictories / math.max(stats.racesPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.raceVictories), formatNumber(stats.racesPlayed), raceVictRate)
	end},
	{"Maximal Win Streak:", 'maxWinStreak'},
	{"Top Times held:", 'toptimes_count'},
	{"Bidlevel:", 'bidlvl'},
	{"Exploded:", function(stats)
		return MuiGetMsg("%s times"):format(stats.exploded)
	end},
	{"Drowned:", function(stats)
		return MuiGetMsg("%s times"):format(stats.drowned)
	end},
	{"Playtime:", function(stats)
		return stats._playTime and formatTimePeriod(stats._playTime, 0) or ''
	end, cache = 'playtime'},
	{"Maps rated:", 'mapsRated'},
	{"Maps bought:", 'mapsBought'},
}

StatsView = {}
StatsView.__mt = {__index = StatsView}
StatsView.elMap = {}

function StatsView.updatePlayTime()
	local now = getRealTime().timestamp
	
	for id, stats in pairs(g_Stats) do
		if(stats.refs > 0) then
			local playTime = stats.time_here
			if(stats._loginTimestamp) then
				playTime = now - tonumber(stats._loginTimestamp) + playTime
			end
			stats._playTime = playTime
			stats.valCache.playtime = false
		end
	end
	
	for wnd, view in pairs(StatsView.elMap) do
		local stats = g_Stats[view.id]
		if(stats and view.sync) then
			view:update()
		end
	end
end

function StatsView:update()
	-- update rest
	local stats = g_Stats[self.id]
	if(not stats) then return end
	
	local values = {}
	for i, info in ipairs(STATS) do
		local value = stats.valCache[info.cache or i]
		if(not value) then
			if(type(info[2]) == 'function') then
				value = info[2](stats)
			else
				value = stats[info[2]]
			end
			stats.valCache[info.cache or i] = value
		end
		table.insert(values, value)
	end
	
	local valuesStr = table.concat(values, '\n')
	guiSetText(self.valuesEl, valuesStr)
end

function StatsView:destroy(ignoreEl)
	self:hide()
	
	local id = self.id
	if(id ~= g_MyId and g_Stats[id].refs == 0) then
		g_Stats[id] = nil
	end
	
	StatsView.elMap[self.el] = nil
	if(not ignoreEl) then
		destroyElement(self.labelsEl)
		destroyElement(self.valuesEl)
	end
end

function StatsView:changeTarget(id)
	local oldSync = self.sync
	self:hide(true)
	self.id = id
	self:update()
	if(oldSync) then
		self:show()
	end
end

function StatsView.getHeight()
	return GUI.getFontHeight() * #STATS
end

function StatsView.create(id, parent, x, y, w, h)
	if(not id) then
		outputDebugString('Wrong ID', 2)
		return false
	end
	
	local self = setmetatable({}, StatsView.__mt)
	
	local labels = {}
	for i, info in ipairs(STATS) do
		table.insert(labels, MuiGetMsg(info[1]))
	end
	local labelsStr = table.concat(labels, '\n')
	
	self.labelsEl = guiCreateLabel(x, y, w * 0.5, h, labelsStr, false, parent)
	self.valuesEl = guiCreateLabel(x + w * 0.5, y, w * 0.5, h, '', false, parent)
	self.id = id
	self.el = self.labelsEl
	
	StatsView.elMap[self.el] = self
	
	self:update()
	
	if(not g_Timer) then
		g_Timer = setTimer(StatsView.updatePlayTime, 1000, 0)
	end
	
	return self
end

function StatsView:show()
	if(self.sync) then return end
	
	local id = self.id
	local force = false
	
	
	if(not g_Stats[id]) then
		g_Stats[id] = {refs = 0, valCache = {}}
		force = true
	end
	
	if(g_Stats[id].refs == 0) then
		--outputDebugString('start sync '..tostring(id), 2)
		triggerServerInternalEvent($(EV_START_SYNC_REQUEST), g_Me, {stats = id}, force)
	end
	g_Stats[id].refs = g_Stats[id].refs + 1
	self.sync = true
end

function StatsView:hide(stopSync)
	if(not self.sync) then return end
	
	local id = self.id
	self.sync = false
	g_Stats[id].refs = g_Stats[id].refs - 1
	if(g_Stats[id].refs == 0) then
		--outputDebugString('pause sync '..tostring(id), 2)
		local req = stopSync and $(EV_STOP_SYNC_REQUEST) or $(EV_PAUSE_SYNC_REQUEST)
		triggerServerInternalEvent(req, g_Me, {stats = id})
	end
end

function StatsView.onSync(sync_tbl)
	-- is it stats sync?
	if(not sync_tbl.stats or not sync_tbl.stats[2]) then return end
	
	-- check id
	local id = sync_tbl.stats[1]
	if(not g_Stats[id] and id ~= g_MyId and id ~= g_Me) then return end
	
	-- create table if not exists
	if(not g_Stats[id]) then
		g_Stats[id] = {refs = 0}
	end
	
	-- update stats
	for field, val in pairs(sync_tbl.stats[2]) do
		g_Stats[id][field] = val
	end
	g_Stats[id]._playTime = g_Stats[id].time_here
	g_Stats[id].valCache = {}
	
	-- update GUI
	for wnd, view in pairs(StatsView.elMap) do
		if(view.id == id) then
			view:update()
		end
	end
end

function StatsPanel.onShow(panel)
	local w, h = guiGetSize(panel, false)
	
	if(not StatsPanel.statsView) then
		StatsPanel.statsView = StatsView.create(g_MyId or g_Me, panel, 10, 10, w - 20, h - 20)
	end
	StatsPanel.statsView:show()
	
	if(UpNeedsBackBtn()) then
		local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
		addEventHandler('onClientGUIClick', btn, UpBack, false)
	end
end

function StatsPanel.onHide(panel)
	StatsPanel.statsView:hide()
end

function StatsPanel.onAccountChange()
	if(StatsPanel.statsView) then
		StatsPanel.statsView:changeTarget(g_MyId or g_Me)
	end
end

UpRegister(StatsPanel)

------------
-- Events --
------------

addInternalEventHandler($(EV_SYNC), StatsView.onSync)
addEventHandler('main.onAccountChange', g_ResRoot, StatsPanel.onAccountChange)
