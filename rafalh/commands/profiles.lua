----------------------------------
-- Global functions definitions --
----------------------------------

local function CmdProfileGet (message, arg)
	local field = arg[1]:sub (2)
	
	assert (g_ProfileFields[field])
	
	local player = false
	if (#arg >= 2) then
		player = findPlayer (message:sub (arg[1]:len () + 2))
	end
	if (not player) then
		player = source
	end
	
	local rows = DbQuery ("SELECT value FROM rafalh_profiles WHERE player=? AND field=? LIMIT 1", g_Players[player].id, field)
	if (rows and rows[1]) then
		scriptMsg ("%s's %s: %s", getPlayerName (player), g_ProfileFields[field].longname, rows[1].value)
	else
		scriptMsg ("%s's %s is not set.", getPlayerName (player), g_ProfileFields[field].longname)
	end
end

local function CmdProfileSet (message, arg)
	local field = arg[1]:sub (5)
	local data = setPlayerProfile (g_Players[source].id, { [field] = message:sub (6 + field:len ()) })
	if (data[field]) then
		scriptMsg ("%s set his %s: %s.", getPlayerName (source), g_ProfileFields[field].longname, data[field])
	end
end

local function PfcInit ()
	for field, data in pairs (g_ProfileFields) do
		CmdRegister (field, CmdProfileGet, false, "Shows player "..data.longname)
		CmdRegister ("set"..field, CmdProfileSet, false, "Changes your "..data.longname)
	end
end

addEventHandler ("onResourceStart", g_ResRoot, PfcInit)
