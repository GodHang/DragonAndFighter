-- Utiltity Tool
-- Date: 2016-6-13
-- 系统工具与常量

UtiltityTool = UtiltityTool or {}

UtiltityTool.sdk = "none"     --sdk
UtiltityTool.iosDebug = false --是否ios提审模式
UtiltityTool.cheatMode = false --是否cheat模式

UtiltityTool.baseVersion = 0   --游戏包基础版本
UtiltityTool.currentVersion = 0    --游戏包当前版本			
UtiltityTool.xcodeVersion = "1.0.0"--appstore提审版本
UtiltityTool.iosAppId = "1119070314"--ios app id

UtiltityTool.downloadStoragePath = "updateDownLoad"--热更新文件目录
UtiltityTool.updateUrl = "http://ftres.365sky.com/halh_Phone/Update_Pack/update/version.ini"--热更新地址

UtiltityTool.VisibleSize = cc.Director:getInstance():getVisibleSize()--显示尺寸

UtiltityTool.PI = 3.1415926
UtiltityTool.MATH_TOLERANCE = 2e-37

--============================================================================================================================
--============================================================================================================================
-- 运行平台
UtiltityTool.targetPlatform = cc.Application:getInstance():getTargetPlatform()

-- luaBridge
if (cc.PLATFORM_OS_IPHONE == UtiltityTool.targetPlatform) or 
   (cc.PLATFORM_OS_IPAD == UtiltityTool.targetPlatform) then 
	UtiltityTool.luaoc = require "src.cocos.cocos2d.luaoc"--sample: UtiltityTool.luaoc.callStaticMethod(className,"registerScriptHandler", {scriptHandler = callback } )
end

if cc.PLATFORM_OS_ANDROID == UtiltityTool.targetPlatform then
	UtiltityTool.luaj = require "src.cocos.cocos2d.luaj"--sample: UtiltityTool.luaj.callStaticMethod(className,"callbackLua",args,sigs)
end

function UtiltityTool.init()
	math.randomseed(os.time())

	-- local manage = CurAssetsManager:create(UtiltityTool.downloadStoragePath, UtiltityTool.updateUrl)
	-- if not manage then
	-- 	print("错误导致游戏无法运行")
	-- 	return
	-- end
	-- manage:retain()

	-- local function onUpdateHandle(callType, arg0, arg1, arg2)		
	-- 	if callType == "onDownload" then
	-- 		print(string.format("onDownload: now: %d, total: %d, %d%%", arg0, arg1, arg2))
	-- 	elseif callType == "onUncompress" then
	-- 		print(string.format("onUncompress: now: %d, total: %d, %d%%", arg0, arg1, arg2))
	-- 	elseif callType == "onError" then
	-- 		print(string.format("onError: %d", arg0))
	-- 	elseif callType == "onSuccess" then
	-- 		print(string.format("onSuccess: %d", arg0))
	-- 		manage:setSearchPath()
	-- 		manage:release()

	-- 		UtiltityTool.currentVersion = arg0

	-- 		require("src/app/MyApp"):create():run()
	-- 	end
	-- end

	-- local handleMgr = ScriptHandlerMgr:getInstance()
 --    handleMgr:registerScriptHandler(manage, onUpdateHandle, 0)

	-- if manage:checkUpdate(UtiltityTool.baseVersion) == 1 then
	-- 	manage:runUpdate()
	-- else
	-- 	print("no Update")
	-- 	manage:setSearchPath()
	-- 	manage:release()

	-- 	UtiltityTool.currentVersion = UtiltityTool.baseVersion

	-- 	require("app.MyApp"):create():run()
	-- end
end

-- 得到数字字符串
function UtiltityTool.returnNumerStr(numer)
	numer = tonumber(numer) or 0

	local str = numer
	
	if numer > 9999 then
		str = math.floor(numer/10000).."万"
	end
	if numer > 99999999 then
		str = math.floor(numer/100000000).."亿"
	end

	return str
end


-- 服务器时间
function UtiltityTool.serverTime()
	return server.time()
end

-- 判断点是否在矩形中
function UtiltityTool.rectContainPoint(rect, point)
	local bRet = false;

	if point.x >= rect.x and point.x <= (rect.x + rect.width) and 
	   point.y >= rect.y and point.y <= (rect.y + rect.height) then
		bRet = true
	end

	return bRet;
end

-- 获取两个向量之间的夹角弧度值
function UtiltityTool.getAngle(x1, y1, x2, y2)
	if x1 == x2 and y1 == y2 then return 0 end

	local vec = UtiltityTool.vec2subtract(x1, y1, x2, y2)
	vec = UtiltityTool.vec2normalize(vec.x, vec.y)

	local f = UtiltityTool.vec2dot(vec.x, vec.y, 0, 1)
	local angle = math.acos(f)

	return angle
end

-- 二维向量相减
function UtiltityTool.vec2subtract(x1, y1, x2, y2)
	return {x = x1-x2, y = y1-y2}
end

-- 二维向量取模
function UtiltityTool.vec2normalize(x1, y1)
	local n = x1 * x1 + y1 * y1;

    if n == 1 then
        return {x = x1, y = y1};
    end
    
    n = math.sqrt(n);
    -- Too close to zero.
    if n < UtiltityTool.MATH_TOLERANCE then
        return {x = x1, y = y1};
    end
    
    n = 1 / n;
    x1 = x1*n;
    y1 = y1*n;

    return {x = x1, y = y1}
end

-- 二维向量取模长度
function UtiltityTool.vec2Length(x, y)
	return math.sqrt(x*x + y*y)
end

-- 二维向量点乘
function UtiltityTool.vec2dot(x1, y1, x2, y2)
	return (x1*x2 + y1*y2)
end

function UtiltityTool.angle2direct(angle, x)
  local direct = 0

  if x > 0 then
    if angle < UtiltityTool.PI/8 then
      direct = 0
    elseif angle < UtiltityTool.PI*3/8 then
      direct = 1
    elseif angle < UtiltityTool.PI*5/8 then
      direct = 2 
    elseif angle < UtiltityTool.PI*7/8 then
      direct = 3
    else
      direct = 4
    end
  else
    if angle < UtiltityTool.PI/8 then
      direct = 0
    elseif angle < UtiltityTool.PI*3/8 then
      direct = 7
    elseif angle < UtiltityTool.PI*5/8 then
      direct = 6 
    elseif angle < UtiltityTool.PI*7/8 then
      direct = 5
    else
      direct = 4
    end
  end

  return direct
end

function UtiltityTool.asc2utf(str)
	return UtilsForLua.get_instance():ASC2UTF((str or ""))
end

function UtiltityTool.utf2asc(str)
	return UtilsForLua.get_instance():UTF2ASC((str or ""))
end

function UtiltityTool.getAttTable(source, str1, str2)
  local temp = Split(source, str1)

  local list = {}
  for i = 1, #temp do
    local data = temp[i]

    local nFindLastIndex = string.find(data, str2, 1)
    list[tonumber(string.sub(data, 1, nFindLastIndex-1))] = tonumber(string.sub(data, nFindLastIndex+1))
  end

  return list
end

-- 判断table是否為空, 返回值: true--空 , false--非空
function UtiltityTool.tableIsEmpty(t)
    if t ~= nil then
        return _G.next( t ) == nil
    else
        return true
    end
end

-- 返回从传入时间点开始已经经过的时间
function UtiltityTool.passTime(t)
	return UtiltityTool.serverTime() - t
end

-- 秒 -> 天
function UtiltityTool.second2day(t)
	return math.ceil(t/(24*60*60))
end

---时间描述字符化*秒 分 时 天
function UtiltityTool.formatTime(num)
  num = math.floor(num)
  local Tian = 0
  local Shi = 0
  local Fen = 0
  local Miao = 0

  if num>86400 then
    Tian = math.floor(num/86400)
  end
  num = num-86400*Tian
  if num>3600 then
    Shi = math.floor(num/3600)
  end
  num = num-3600*Shi

  if num>60 then
    Fen = math.floor(num/60)
  end

  Miao = math.floor(num-60*Fen)

  ------------------------------
  if Tian>0 then
    return Tian .. "天" .. Shi .. "时" --.. Fen .. "分" ..  Miao .. "秒"
  end
  if Shi>0 then
    return Shi .. "时".. Fen .. "分" --..  Miao .. "秒"
  end
  if Fen>0 then
    return Fen .. "分"  .. Miao .. "秒"
  end
  return Miao .. "秒"

end

-- 连接服务器
function UtiltityTool.connect(ip, port)
	SocketEngine:getInstance():stop_service()
	SocketEngine:getInstance():start_service()

	local isSuc = SocketEngine:getInstance():connect(ip, port)
    if not isSuc then
        cclog("error:链接网络失败！")
    end

    return isSuc
end

function __callBackApplicationDidEnterBackground()
	if cc.PLATFORM_OS_WINDOWS ~= UtiltityTool.targetPlatform then
		print("callBack Application Did Enter Background")
	end
end

function __callBackApplicationWillEnterForeground()
	if cc.PLATFORM_OS_WINDOWS ~= UtiltityTool.targetPlatform then
		print("callBack Application Will Enter Foreground")
	end
end