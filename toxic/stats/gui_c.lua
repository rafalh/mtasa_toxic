-- Includes
#include 'include/config.lua'

-- Globals
local g_Timer = nil

local StatsPanel = {
	name = "Statistics",
	img = 'stats/img/icon.png',
	tooltip = "Check your statistics",
	width = 230,
	height = 270,
	prio = -100,
}

--------------------------------
-- Local function definitions --
--------------------------------

local STATS = {
	{"Cash:", function(stats)
		return formatMoney(stats.cash)
	end},
	{"Points:", function(stats)
		return formatNumber(stats.points)..' '..MuiGetMsg('(level %u)'):format(LvlFromExp(stats.points))
	end},
	{"Rank:", '_rank'},
#if(DM_STATS) then
	{"DM Victories:", function(stats)
		local dmVictRate = stats.dmVictories / math.max(stats.dmPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.dmVictories), formatNumber(stats.dmPlayed), dmVictRate)
	end},
	{"Hunters taken:", function(stats)
		local huntRate = stats.huntersTaken / math.max(stats.dmPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.huntersTaken), formatNumber(stats.dmPlayed), huntRate)
	end},
#end
#if(DD_STATS) then
	{"DD Victories:", function(stats)
		local ddVictRate = stats.ddVictories / math.max(stats.ddPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.ddVictories), formatNumber(stats.ddPlayed), ddVictRate)
	end},
	{"DD Kills:", function(stats)
		return formatNumber(stats.kills)
	end},
#end
#if(RACE_STATS) then
	{"Race Victories:", function(stats)
		local raceVictRate = stats.raceVictories / math.max(stats.racesPlayed, 1) * 100
		return ('%s/%s (%.1f%%)'):format(formatNumber(stats.raceVictories), formatNumber(stats.racesPlayed), raceVictRate)
	end},
#end
	{"Maximal Win Streak:", 'maxWinStreak'},
#if(TOP_TIMES) then
	{"Top Times held:", 'toptimes_count'},
#end
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
	StUpdatePlayTime()
	
	for wnd, view in pairs(StatsView.elMap) do
		local stats = StGet(view.id)
		if(stats and view.sync) then
			view:update()
		end
	end
end

function StatsView:update()
	-- update rest
	local stats = StGet(self.id)
	local valCache = StGetValCache(self.id)
	if(not stats) then return end
	
	local values = {}
	for i, info in ipairs(STATS) do
		local value = valCache[info.cache or i]
		if(not value) then
			if(type(info[2]) == 'function') then
				value = info[2](stats)
			else
				value = stats[info[2]]
			end
			assert(value, info[1])
			valCache[info.cache or i] = value
		end
		table.insert(values, value)
	end
	
	local valuesStr = table.concat(values, '\n')
	guiSetText(self.valuesEl, valuesStr)
end

function StatsView:destroy(ignoreEl)
	self:hide()
	
	if(self.id ~= g_SharedState.accountId) then
		StDeleteIfNotUsed(self.id)
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
		Debug.warn('Wrong ID')
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
	
	StStartSync(self.id)
	self.sync = true
end

function StatsView:hide(stopSync)
	if(not self.sync) then return end
	
	self.sync = false
	StStopSync(self.id, stopSync)
end

function StatsPanel.onShow(panel)
	local w, h = guiGetSize(panel, false)
	
	if(not StatsPanel.statsView) then
		StatsPanel.statsView = StatsView.create(g_SharedState.accountId or g_Me, panel, 10, 10, w - 20, h - 20)
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
		StatsPanel.statsView:changeTarget(g_SharedState.accountId or g_Me)
	end
end

addInitFunc(function()
	addEventHandler('main.onAccountChange', resourceRoot, StatsPanel.onAccountChange)
	UpRegister(StatsPanel)
end)
