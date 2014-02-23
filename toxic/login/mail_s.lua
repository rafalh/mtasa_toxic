
#include 'include/config.lua'

#if(PASSWORD_RECOVERY) then

local g_Config = false

Mail = Class('Mail')

local function loadSmtpConfig()
	local config = {host = false, port = 25, username = false, password = false, email = false}
	
	local node = xmlLoadFile('conf/smtp.xml')
	if(not node) then return false end
	
	for i, subnode in ipairs(xmlNodeGetChildren(node)) do
		local key = xmlNodeGetName(subnode)
		local val = xmlNodeGetValue(subnode)
		if(val and val:len() > 0) then
			if(config[key] ~= nil) then
				config[key] = val
			else
				Debug.warn('Invalid SMTP option: '..key)
			end
		end
	end
	
	config.port = tonumber(config.port)
	
	if(not config.host or not config.port or not config.username or not config.password) then
		Debug.warn('SMTP configuration is invalid!')
		return false
	end
	
	xmlUnloadFile(node)
	return config
end

function Mail.__mt.__index:init()
	if(not g_Config) then
		g_Config = loadSmtpConfig()
	end
	self.config = g_Config
end

function Mail.__mt.__index:send()
	if(not self.to) then Debug.warn('Field "to" is not set') return false end
	if(not self.subject) then Debug.warn('Field "subject" is not set') return false end
	if(not self.body) then Debug.warn('Field "body" is not set') return false end
	
	local serverNameFiltered = trimStr(getServerName():gsub('[^%w%s%p]', ''))
	local params = {
		host = self.config.host, port = self.config.port,
		username = self.config.username, password = self.config.password,
		from = self.from or self.config.email, fromTitle = self.fromTitle or serverNameFiltered,
		to = self.to, toTitle = self.toTitle,
		subject = self.subject}
	
	if(not fetchRemote('http://ravin.tk/api/mta/sendmail.php?'..urlEncodeTbl(params), function(responseData, errno)
		if(responseData == 'ERROR') then
			Debug.err('sendMail failed: '..errno)
			if(self.callback) then
				self.callback(false)
			end
		else
			local status, err = fromJSON(responseData)
			local success = (status == 1)
			
			if(not result or not success) then
				Debug.err('sendMail failed: '..tostring(err))
			end
			
			if(self.callback) then
				self.callback(success)
			end
		end
	end, self.body, false)) then return false end
	
	return true
end

#end
