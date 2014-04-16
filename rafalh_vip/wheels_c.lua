local function replaceWheels()
	local txd
	if(fileExists('wheels/txd.txd')) then
		txd = engineLoadTXD('wheels/txd.txd')
	end
	
	for i = 1070, 1100 do
		local dffPath = 'wheels/'..i..'.dff'
		if(fileExists(dffPath)) then
			if(txd) then
				engineImportTXD(txd, i)
			end
			
			local dff = engineLoadDFF(dffPath, i)
			engineReplaceModel(dff, i)
		end
	end
end

addEventHandler('onClientResourceStart', resourceRoot, replaceWheels)
