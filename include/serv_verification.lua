-- Includes
#include 'obfuscation.lua'

-- Deprecated
#EV_SERVER_VERIFICATION = "\"onClientRafalhShared1\""
#VERIFY_SERVER_FUNC = "verify"

#SERV_VERIFICATION_KEY = OBFUSCATE('8_ccDr-8')
#EV_VERIFIER_READY = OBFUSCATE('AOGltgWlbU')
#EV_VERIFY_REQ = OBFUSCATE('YSRDCiwdyY')
#EV_VERIFIED = OBFUSCATE('0CqFvjg0uc')

#function VERIFY_SERVER_BEGIN(resNameMD5)
#assert(resNameMD5:len() == 32)
	
	local function isNativeFunction(func)
		local info = debug.getinfo(func, 'S')
		return info.what == 'C'
	end
	
	local f = {md5 = md5, getResourceName = getResourceName, getThisResource = getThisResource, rnd = math.random}
	for i, f in pairs(f) do
		if(not isNativeFunction(f)) then return end
	end
	
	if(f.md5(f.getResourceName(f.getThisResource())) ~= '$(resNameMD5)') then return end
	
	addEvent($(EV_VERIFIER_READY))
	addEvent($(EV_VERIFY_REQ))
	addEvent($(EV_VERIFIED))
	
	local tryVerify
	tryVerify = function()
		local n = f.rnd(0, 65000)
		local onVerified
		onVerified = function(code)
			if(code ~= f.md5($(SERV_VERIFICATION_KEY)..tostring(n^2+93))) then return end
			removeEventHandler($(EV_VERIFIED), resourceRoot, onVerified)
			removeEventHandler($(EV_VERIFIER_READY), root, tryVerify)
#end

#function VERIFY_SERVER_END()
		end
		addEventHandler($(EV_VERIFIED), resourceRoot, onVerified)
		
		triggerEvent($(EV_VERIFY_REQ), resourceRoot, n)
	end
	addEventHandler($(EV_VERIFIER_READY), root, tryVerify)
	tryVerify()
#end
