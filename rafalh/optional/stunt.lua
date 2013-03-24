-------------------
-- Custom events --
-------------------

addEvent ( "onPlayerStuntComplete", true )

------------
-- Events --
------------

addEventHandler("onPlayerStuntComplete", g_Root, function(stuntType, vehicle, time, distance, height, rotation, greatLanding)
	if(SmGetBool("stunt_bonus")) then
		local addcash
		if ( stuntType == "Jump" ) then
			addcash = distance * 4 + height * 8 + rotation * 200/360
			if ( greatLanding ) then
				addcash = addcash * 2
			end
		elseif ( stuntType == "Two-Wheeler" ) then
			addcash = time * 100
		elseif ( stuntType == "Wheelie" ) then
			addcash = distance * 3
		elseif ( stuntType == "Stoppie" ) then
			addcash = distance * 6
		else
			outputDebugString ( "Unknown stunt type: "..tostring ( stuntType ), 2 )
		end
		if(addcash) then
			local pdata = Player.fromEl(source)
			pdata.accountData:add("cash", addcash)
			privMsg(source, "You get %s for your stunt!", formatMoney(addcash))
		end
	end
end)
