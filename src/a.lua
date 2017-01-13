
local MR = 2
local ML = 3
local qipan = {
	[1] = {
		[1] = 1,[2] = 2,
	},
	[2] = {
		[1] = 1,[2] = 2,
	},
	[3] = {
		[1] = 1,[2] = 2,
	},
}
local whiteList = {raw = {},line = {},xiexian = {}}
local blackList = {raw = {},line = {},xiexian = {}}
local function check(i,j)
	if qipan[i][j]==nil then return end
	if whiteList.raw[#whiteList.raw]~=qipan[i][j] then
		return
	end
	if whiteList.line[#whiteList.line]~=qipan[i][j] then
		return
	end
	if whiteList.xiexian[#whiteList.xiexian]~=qipan[i][j] then
		return
	end

	if #whiteList.raw==5 or #whiteList.line==5 or #whiteList.xiexian==5 then
		return
	end

	if qipan[i][j]==white then
		whiteList.raw[1]=qipan[i][j]
		whiteList.line[1]=qipan[i][j]
		whiteList.xiexian[1]=qipan[i][j]
		if qipan[i+1]~=nil then
			if qipan[i+1][j]==white then
				whiteList.line[#whiteList.line+1] = qipan[i+1][j]
				check(i+1,j)
			end
		end
		if qipan[i][j+1]~=nil then
			if qipan[i][j+1]==white then
				whiteList.raw[#whiteList.raw+1] = qipan[i][j+1]
				check(i,j+1)
			end
		end
		if qipan[i]~=nil and qipan[i+1][j+1] then
			if qipan[i+1][j+1]==white then
				whiteList.xiexian[#whiteList.xiexian+1] = qipan[i+1][j+1]
				check(i+1,j+1)
			end
		end

	elseif qipan[i][j]==black then
		--一样的
	end
end

local function checkAll()
	for i=1,ML do
		for j=1,MR do
			whiteList = {raw = {},line = {},xiexian = {}}
			blackList = {raw = {},line = {},xiexian = {}}
			check(i,j)
			if #whiteList.raw==5 or #whiteList.line==5 or #whiteList.xiexian==5 then
				print("white win")
				return
			end
			if #blackList.raw==5 or #blackList.line==5 or #blackList.xiexian==5 then
				print("black win")
				return
			end
		end
	end
end