function VipGetVehicleUpgradeSlot(upg)
	local slotNameToID = {
		['Hood']           = 0,  ['Vent']          = 1,  ['Spoiler']      = 2,  ['Sideskirt']   = 3,
		['Front Bullbars'] = 4,  ['Rear Bullbars'] = 5,  ['Headlights']   = 6,  ['Roof']        = 7,
		['Nitro']          = 8,  ['Hydraulics']    = 9,  ['Stereo']       = 10, ['Unknown']     = 11,
		['Wheels']         = 12, ['Exhaust']       = 13, ['Front Bumper'] = 14, ['Rear Bumper'] = 15,
		['Misc']           = 16,
	}
	local slotName = getVehicleUpgradeSlotName(upg)
	return slotNameToID[slotName]
end