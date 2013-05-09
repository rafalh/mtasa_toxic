function intToBin(num, bytes)
	num = math.floor(num)
	local ret = ""
	if(num < 0) then
		num = -num
		ret = string.char(128 + (num % 128))
	else
		ret = string.char(num % 128)
	end
	num = math.floor(num / 128)
	
	for i = 2, bytes do
		ret = ret..string.char(num % 256)
		num = math.floor(num / 256)
	end
	return ret
end

function uintToBin(num, bytes)
	num = math.floor(num)
	local ret = ""
	for i = 1, bytes do
		ret = ret..string.char(num % 256)
		num = math.floor(num / 256)
	end
	return ret
end

function binToInt(data)
	local num = 0
	
	for i = data:len(), 2, -1 do
		local b = data:byte(i)
		num = num*256
		num = num + b
	end
	
	num = num*128
	local b = data:byte(1)
	if(b >= 128) then
		num = num + b - 128
		num = -num
	else
		num = num + b
	end
	
	return num
end

function binToUint(data)
	local num = 0
	for i = data:len(), 1, -1 do
		local b = data:byte(i)
		num = num*256
		num = num + b
	end
	
	return num
end
