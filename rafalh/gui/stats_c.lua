--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local g_Timer = nil
local g_Stats = {}

local StatsPanel = {
	name = "Statistics",
	img = "img/userpanel/stats.png",
	tooltip = "Check your statistics",
	width = 230,
	height = 270,
}

--------------------------------
-- Local function definitions --
--------------------------------

StatsView = {}
StatsView.__mt = {__index = StatsView}
StatsView.elMap = {}

function StatsView.updatePlayTime()
	local now = getRealTime().timestamp
	
	for wnd, view in pairs(StatsView.elMap) do
		local stats = g_Stats[view.id]
		if(stats and view.sync) then
			local playTime = stats.time_here
			if(stats._loginTimestamp) then
				playTime = now - tonumber(stats._loginTimestamp) + playTime
			end
			guiSetText(view.gui._time_here, formatTimePeriod(playTime, 0))
		end
	end
end

function StatsView:update()
	-- update playtime
	StatsView.updatePlayTime()
	
	-- update rest
	local stats = g_Stats[self.id]
	if(not stats) then return end
	
	local gui = self.gui
	guiSetText(gui.cash, formatMoney(stats.cash))
	guiSetText(gui.points, formatNumber(stats.points))
	guiSetText(gui._rank, stats._rank)
	local dmVictRate = stats.dmVictories / math.max(stats.dmPlayed, 1) * 100
	guiSetText(gui.dmVictories, ("%s/%s (%.1f%%)"):format(formatNumber(stats.dmVictories), formatNumber(stats.dmPlayed), dmVictRate))
	local huntRate = stats.huntersTaken / math.max(stats.dmPlayed, 1) * 100
	guiSetText(gui.huntersTaken, ("%s/%s (%.1f%%)"):format(formatNumber(stats.huntersTaken), formatNumber(stats.dmPlayed), huntRate))
	local ddVictRate = stats.ddVictories / math.max(stats.ddPlayed, 1) * 100
	guiSetText(gui.ddVictories, ("%s/%s (%.1f%%)"):format(formatNumber(stats.ddVictories), formatNumber(stats.ddPlayed), ddVictRate))
	local raceVictRate = stats.raceVictories / math.max(stats.racesPlayed, 1) * 100
	guiSetText(gui.raceVictories, ("%s/%s (%.1f%%)"):format(formatNumber(stats.raceVictories), formatNumber(stats.racesPlayed), raceVictRate))
	guiSetText(gui.maxWinStreak, stats.maxWinStreak)
	guiSetText(gui.toptimes_count, stats.toptimes_count)
	guiSetText(gui.bidlvl, stats.bidlvl)
	guiSetText(gui.exploded, MuiGetMsg("%s times"):format(stats.exploded))
	guiSetText(gui.drowned, MuiGetMsg("%s times"):format(stats.drowned))
	guiSetText(gui.mapsRated, stats.mapsRated)
	guiSetText(gui.mapsBought, stats.mapsBought)
end

function StatsView:destroy()
	self:hide()
	
	local id = self.id
	if(id ~= g_MyId and g_Stats[id].refs == 0) then
		g_Stats[id] = nil
	end
	
	self.gui:destroy()
	StatsView.elMap[self.el] = nil
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
	return GUI.getTemplate("stats").h
end

function StatsView.create(id, parent, x, y, w, h)
	if(not id) then
		outputDebugString("Wrong ID", 2)
		return false
	end
	
	local self = setmetatable({}, StatsView.__mt)
	self.gui = GUI.create("stats", x, y, w, h, parent)
	self.id = id
	self.el = self.gui.wnd
	
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
		g_Stats[id] = { refs = 0 }
		force = true
	end
	
	if(g_Stats[id].refs == 0) then
		--outputDebugString("start sync "..tostring(id), 2)
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
		--outputDebugString("pause sync "..tostring(id), 2)
		local req = stopSync and $(EV_STOP_SYNC_REQUEST) or $(EV_PAUSE_SYNC_REQUEST)
		triggerServerInternalEvent(req, g_Me, {stats = id})
	end
end

function StatsView.onSync(sync_tbl)
	-- is it stats sync?
	if(not sync_tbl.stats) then return end
	
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
	
	local btn = guiCreateButton(w - 80, h - 35, 70, 25, "Back", false, panel)
	addEventHandler("onClientGUIClick", btn, UpBack, false)
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
addEventHandler("main.onAccountChange", g_ResRoot, StatsPanel.onAccountChange)
