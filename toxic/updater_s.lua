Updater = {
	currentVer = 152,
	list = {
		ver = 150,
		func = function()
			local rows = DbQuery("SELECT map, player, rec, cp_times FROM "..BestTimesTable.." WHERE length(rec)>0 OR length(cp_times)>0")
			DbQuery("UPDATE "..BestTimesTable.." SET rec=0 WHERE length(rec)=0")
			DbQuery("UPDATE "..BestTimesTable.." SET cp_times=0 WHERE length(cp_times)=0")
			for i, data in ipairs(rows) do
				if(data.rec ~= "") then
					DbQuery("INSERT INTO "..BlobsTable.." (data) VALUES("..DbBlob(data.rec)..")")
					local id = Database.getLastInsertID()
					if(id == 0) then outputDebugString("last insert ID == 0", 2) end
					DbQuery("UPDATE "..BestTimesTable.." SET rec=? WHERE map=? AND player=?", id, data.map, data.player)
				end
				if(data.cp_times ~= "") then
					DbQuery("INSERT INTO "..BlobsTable.." (data) VALUES("..DbBlob(data.cp_times)..")")
					local id = Database.getLastInsertID()
					if(id == 0) then outputDebugString("last insert ID == 0", 2) end
					DbQuery("UPDATE "..BestTimesTable.." SET cp_times=? WHERE map=? AND player=?", id, data.map, data.player)
				end
				
				coroutine.yield()
			end
			outputDebugString(#rows.." best times updated", 3)
			return true
		end
	},
	{
		ver = 151,
		func = function()
			DbQuery("UPDATE "..BestTimesTable.." SET timestamp=0 WHERE timestamp IS NULL")
			
			if(not DbRecreateTable(BestTimesTable)) then
				return false, "Failed to recreate best times table"
			end
			return true
		end
	},
	{
		ver = 152,
		func = function()
			DbQuery("UPDATE "..PlayersTable.." SET account=NULL WHERE account=''")
			if(not DbRecreateTable(PlayersTable)) then
				return false, "Failed to recreate players table"
			end
			return true
		end
	},
}
