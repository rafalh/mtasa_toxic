-- Include guard
#if(includeGuard()) then return end

-- Includes
#include 'obfuscation.lua'

-- Key
#SERV_VERIFICATION_KEY = OBFUSCATE('8_ccDr-8')

-- Events
#EV_VERIFIER_READY = OBFUSCATE('AOGltgWlbU')
#EV_VERIFY_REQ = OBFUSCATE('YSRDCiwdyY')
#EV_VERIFIED = OBFUSCATE('0CqFvjg0uc')

addEvent($(EV_VERIFIER_READY))
addEvent($(EV_VERIFY_REQ))
addEvent($(EV_VERIFIED))
