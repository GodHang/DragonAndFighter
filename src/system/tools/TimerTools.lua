--定时器工具
--============================================================
--循环计时器，如果time为nil则默认按dt来，如果loops=-1或者nil则无限播放 
--它会返回一个id
local InitTimer=nil
local TimerAccount = 0
local TimerGroup = {}
local function DoFun(k,dt)
	if TimerGroup[k].ctime<=dt then
		result_Timer = TimerGroup[k].cfun(dt)
		if TimerGroup[k]==nil then 
			return 
		end
		if result_Timer == false then
			Timer_Delete(k)
			return
		end
		if TimerGroup[k].cloops==0 then
			Timer_Delete(k)
			return
		end
		TimerGroup[k].cloops=TimerGroup[k].cloops-1
		return
	end
	TimerGroup[k].cTempLeft = TimerGroup[k].cTempLeft -dt
	if TimerGroup[k].cTempLeft<=0 then
		local fun = TimerGroup[k].cfun
		local result = true
		if TimerGroup[k].ctime==0 then
			result = fun(dt)
		else
			result = fun(TimerGroup[k].ctime-TimerGroup[k].cTempLeft)
		end
		if TimerGroup[k]==nil then 
			return 
		end
		if result == false then
			Timer_Delete(k)
			return
		end
		TimerGroup[k].cTempLeft = TimerGroup[k].ctime
		if TimerGroup[k].cloops==0 then
			Timer_Delete(k)
		else
			TimerGroup[k].cloops=TimerGroup[k].cloops-1
		end
	end
end
local function TiemrFun(dt)
	for k,v in pairs(TimerGroup) do
		DoFun(k,dt)
	end
end
function Timer_Create(fun,time,loops,info,level,mark)
	if fun==nil then return end
	if level == nil then level = 0 end
	if InitTimer==nil then
		InitTimer = scheduler:scheduleScriptFunc(TiemrFun, 0, false)
	end
	if time == nil then time =0 end
	if loops ==nil then loops=-1 end
	if info ==nil then
		cclog("error:Timer_Create函数必须声明其注释消息！")
		info =info +10
	else
		info = "间隔[" .. time .. "] 循环[" .. loops .. "] 注释:" ..	info
	end
	
	local ID = TimerAccount
	TimerAccount = TimerAccount +1
	TimerGroup[ID] = 
	{
		cfun = fun,
		ctime = time,
		cTempLeft = time,
		cloops = loops,
		cinfo = info,
		clevel = level,
	}
	cclog("启动计时器:" ..	info)
	return ID
end
function Timer_Delete(id )
	if id==nil then return end
	if TimerGroup[id]~=nil then
	cclog("关闭计时器:" ..	TimerGroup[id].cinfo)
	TimerGroup[id].cfun=nil
	TimerGroup[id].ctime=nil
	TimerGroup[id].cTempLeft=nil
	TimerGroup[id].cloops=nil
	TimerGroup[id].cinfo=nil
	TimerGroup[id].clevel=nil
	TimerGroup[id] = nil
	end
end

function GetTimer(id)
	return TimerGroup[id]
end