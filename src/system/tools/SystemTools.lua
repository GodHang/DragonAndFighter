

--字符串裁剪
--参数1：待分割的字符串
--参数2：分割字符
function Split(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

--字符串裁剪
--参数1：待分割的字符串
--参数2：分割字符
function SplitForInt(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = tonumber(string.sub(szFullString, nFindStartIndex, string.len(szFullString)))
			break
		end
		nSplitArray[nSplitIndex] = tonumber(string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1))
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

function ChangeAniAnchor(sender,pointX,pointY)
	local point = cc.p(pointX,pointY)
	local oldAnchor = sender:getAnchorPoint()
	local WidWidth = 512
	local WidHeight = 512
	local oldPos = {x=sender:getPositionX()-WidWidth*oldAnchor.x,y=sender:getPositionY()-WidHeight*oldAnchor.y}
	sender:setAnchorPoint(point)
	sender:setPosition(oldPos.x+point.x*WidWidth ,oldPos.y+point.y*WidHeight )
end
---------------字符替换系统---------------------------- 如果doTheFst为真 则只替换一次
function StringReplace(str,word,reto,doTheFst)
	local pos1
	local pos2
	pos1,pos2=string.find(str,word)	-- Monster-6705	; Monster-
	if pos1~=nil then 
		if pos1<=1 then
			str=reto .. string.sub(str,pos1-1+string.len(word)+1)
		else
			str=string.sub(str,0,pos1-1) .. reto .. string.sub(str,pos1-1+string.len(word)+1)
		end
		if doTheFst~= true then
			str=StringReplace(str,word,reto)
		end
	end
	return str
end

local Tbl_RichBox_Data = {}
local EditBox_Test = {}

--结构解析
local function TestStruct(Words,Start)
	if Words[Start]=='<' then
		if Words[Start+1]=='/' then
			if	 Words[Start+2]=='F' then--</F字体		 </F0,20,255-255-255-255,funF/>	下划线.加粗(0,01,10,11) 字号(1-72) 颜色(r-g-b-a) 点击跳转(none为没有)
			  return "字体"
			elseif Words[Start+2]=='I' then--</IindexI/>	 道具
			  return "道具"
			elseif Words[Start+2]=='P' then--</Pmapid-posx-posy-playername-reason-timeP/>	 位置	后面三项是可选的
			  return "位置"
			elseif Words[Start+2]=='A' then--</ApathA/>	 动画
			  return "动画"
			elseif Words[Start+2]=='T' then--</TpathT/>	 图片
			  return "图片"
			elseif Words[Start+2]=='S' then--</Sfuntype-valueS/>	 特殊的
			  return "函数"
			end
		end
	end
	return "不是代码" 
end
local function GetStringFormStruct(Words,Start)
	local tempInt=0
	for i=Start,#Words do
		if Words[i]=="/" then
			if Words[i+1]==">" then
				tempInt=i+1
				break
			end
		end
	end
	--将Start到tempInt之间的数据返回
	local Stringdata=""
	for i=Start+3,tempInt-3 do
		Stringdata = Stringdata .. Words[i]
	end
	return Stringdata,tempInt
end
--预铺设
local function GetStr_ToNextStruct(Words,Start,SingleSize,ReadyPosX,SWidth)
	local code = 1	--0不正常	1因形式变化而结束	2因换行符 3因自动换行
	--
	local tempInt=0
	local NowWidth = 0 --总字宽
	local ThisWordsWidth = 0 -- 临时字宽
	----测试一个字符的宽度---
	if EditBox_Test[SingleSize]==nil then
		EditBox_Test[SingleSize] = cc.Label:createWithTTF(" ","res/font/msyh.ttf",SingleSize)
		EditBox_Test[SingleSize]:retain()
	end
	for i=Start,#Words do
		if Words[i]=="<" then
			if Words[i+1]=="/" then
				tempInt=i-1
				code=1
				break
			end
		end
		if Words[i]=='\n' then
			tempInt=i-1
			code=2
			break
		end
		EditBox_Test[SingleSize]:setString(Words[i])
		ThisWordsWidth=EditBox_Test[SingleSize]:getContentSize().width
		--字节长度到换行
		if ThisWordsWidth + NowWidth + ReadyPosX > SWidth then
			--cclog("error:富文本--" .. Words[i] .. "--要求换行，此刻位置" .. (NowWidth + ReadyPosX)	.. ",限制：" ..SWidth )
			tempInt=i-1
			code=3
			break
		end
		tempInt=i
		NowWidth = NowWidth + ThisWordsWidth
	end
	--将Start到tempInt之间的数据返回
	local Stringdata=""
	for i=Start,tempInt do
	  Stringdata = Stringdata .. Words[i]
	end
	if code ==2 then
	  return Stringdata,code,tempInt-Start+2
	else
	  return Stringdata,code,tempInt-Start+1
	end
end
--预铺设*other类型
local function GetStr_ToNextObject(Words,SingleSize,ReadyPosX,SWidth)
	local tempInt=0
	local NowWidth = 0 --总字宽
	local ThisWordsWidth = 0 -- 临时字宽
	----测试一个字符的宽度---
	if EditBox_Test[SingleSize]==nil then
		EditBox_Test[SingleSize] = cc.Label:createWithTTF(" ","res/font/msyh.ttf",SingleSize)
		EditBox_Test[SingleSize]:retain()
	end
	for i=1,#Words do
		EditBox_Test[SingleSize]:setString(Words[i])
		ThisWordsWidth=EditBox_Test[SingleSize]:getContentSize().width
		--字节长度到换行
		if ThisWordsWidth + NowWidth + ReadyPosX > SWidth then
			--cclog("error:富文本--" .. Words[i] .. "--要求换行，此刻位置" .. (NowWidth + ReadyPosX)	.. ",限制：" ..SWidth )
			tempInt=i-1
			break
		end
		tempInt=i
		NowWidth = NowWidth + ThisWordsWidth
	end
	return tempInt
	--返回能创建的数量
end
--特殊函数
function Rich_TextBox_Function(functions,value)
	if functions==nil then return end
	local valuestal = Split(value,"|")
	if functions == "招魂幡" then
		Multiplayer_ZhaoHuan(tonumber(valuestal[1]),tostring(valuestal[2]))
		return
	end
end

--改变富文本控件的文字颜色（需要已经调用过MMR_EditRichText_Plus设置了文字）
--参数：layout = 富文本控件，color = 新的字体颜色cc.c4b(r,g,b,a)
--返回：原文字颜色
function RichText_ChangeColor( layout, color )
	if layout == nil or layout:getChildByTag(-1001) == nil then return end
	local boxFont = layout:getChildByTag(-1001):getChildByName("lbText")
	--对于纯文本的富文本来说,boxFont是一个Label
	if boxFont == nil then return end
	if color ~= nil then 
	   boxFont:setTextColor(color)
	end
	return boxFont:getTextColor()
end

--获取富文本控件的文字（需要已经调用过MMR_EditRichText_Plus设置了文字）
--参数：layout = 富文本控件
function RichText_GetText( layout )
	if layout == nil then return end
	local boxFont = layout:getChildByTag(-1001):getChildByName("lbText")
	--对于纯文本的富文本来说,boxFont是一个Label
	if boxFont == nil then return end
	return boxFont:getString()
end


function MMR_EditRichText_Plus(layout,text,IsMid,LineMod,TopLeftX,TopLeftY,SWidth,BgMode,Return_FullSize)
	if NO_RICHTEXT then return SWidth,SWidth end
	if layout==nil then 
		cclog("error:富文本检测到错误 layout是一个nil！text=" .. tostring(text))
		return 
	end

	--cclog("[tips:]富文本：" .. text .. ",SWidth=" .. tostring(SWidth))
	text = RichTextBoxReplace(text)
	--参数初始化
	if Return_FullSize ==nil	then Return_FullSize=false end
	local MaxWidth =0
	local UTF8Words={}
	--字符统一转码
	--UTF-8的编码规则1.字符的第一个字节范围：0x00-0x7F(0-127)或者0xC2-0xF4(194-244)
	--2.0xC2,0xC1,0xF5-0xFF(192,193和245-255)不会出现在UTF8编码中
	--3.0x80-0xBF(128-191)只会出现在第二个及随后的编码中(针对多字节编码，如汉子)
	for uchar in string.gfind(text, "[%z\1-\127\194-\244][\128-\191]*") do 
		 --将text中的每个字符映射到tab中	 0、1-127、194-244
		UTF8Words[#UTF8Words+1] = uchar 
	end
	if TopLeftX==nil then
		TopLeftX=0
	end
	if TopLeftY==nil then
		TopLeftY=0
	end
	---------------创建基础对象---------------
	local ContentSize = layout:getContentSize()
	if ContentSize==nil then
		 ContentSize = layout:getContentSize()
	end
	if SWidth == nil then
		SWidth = ContentSize.width
	else
		ContentSize.width = SWidth
	end


	--清空label中的东西
	local findswordsx,findswordsy=string.find(layout:getDescription(),"Label")
	if findswordsx==nil then
	else
		layout:setString("")
	end
	local Return_Layer = ccui.Layout:create()
	--Return_Layer:setCameraMask(cc.CameraFlag.USER1)
	Return_Layer:setAnchorPoint(cc.p(0,1))
	Return_Layer:setPosition(cc.p(TopLeftX,TopLeftY))


	-------循环遍历结构
	local Font_I=0 --当前读取的字节位置
	
	local Font_Type=0	 --下划线.加粗(0,01,10,11) 
	local Font_Size=20	--字号(1-72) 
	local Font_r=255	--颜色(r-g-b-a) 
	local Font_g=255	--颜色(r-g-b-a) 
	local Font_b=255	--颜色(r-g-b-a) 
	local Font_a=255	--颜色(r-g-b-a) 
	local Font_JUMP="none" --点击跳转(none为没有)
	local Sp_Type = 1	--鉴别文字跳转属类（用于Font_JUMP支援） 1普通跳转 2玩家 3装备/道具 

	local Pos = {x=0,y=0,width=0,height=0} --Y记录了上一行最大值 X当前坐标 height 容器最终高度

	---存储容器
	local Box_Font	 = {}

	-------------------------------------------------------------
	local DuiQi_X_Form =1
	local DuiQi_X_To = 1 
	local function DuiQi_X()
		if DuiQi_X_To<1 then DuiQi_X_To =1 end
		--计算 行宽度Pos.x	限制宽度SWidth
		if IsMid == "居中"	then
		for i=DuiQi_X_Form,DuiQi_X_To do
			Box_Font[i]:setPositionX(Box_Font[i]:getPositionX() + (SWidth-Pos.x)/2)
		end
		DuiQi_X_Form = DuiQi_X_To +1
		elseif IsMid == "右对齐" then
		for i=DuiQi_X_Form,DuiQi_X_To do
			Box_Font[i]:setPositionX(Box_Font[i]:getPositionX() + (SWidth-Pos.x))
		end
		DuiQi_X_Form = DuiQi_X_To +1
		end
	end
	for i=1,#UTF8Words do
		Font_I=Font_I+1
		if Font_I>#UTF8Words then
		  break
		end
		--检查是不是该结构
		local ReturnDataString=TestStruct(UTF8Words,Font_I)
		if ReturnDataString=="字体" then
			--读取整个结构数据
			ReturnDataString,Font_I=GetStringFormStruct(UTF8Words,Font_I)
			--解析</F	 “0,20,255-255-255-255,fun”	 F/>
			local Font_Split_1=Split(ReturnDataString,",")
			local Font_Split_2=SplitForInt(Font_Split_1[3],"-")
			Font_Type=tonumber(Font_Split_1[1])
			Font_Size=tonumber(Font_Split_1[2])
			Font_r=tonumber(Font_Split_2[1])
			Font_g=tonumber(Font_Split_2[2])
			Font_b=tonumber(Font_Split_2[3])
			Font_a=tonumber(Font_Split_2[4])
			Sp_Type=1
			Font_JUMP=Font_Split_1[4]

			--cclog("富文本" .. text .. "解析结果:r=" .. Font_r .. ",g=" .. Font_g..",b=" .. Font_b.. ",a="..Font_a)
		elseif ReturnDataString=="道具" then
			--找到
			ReturnDataString,Font_I=GetStringFormStruct(UTF8Words,Font_I)
			local items_id = tonumber(ReturnDataString)
			local quality = 1
			local item_name = ""
			local item_name_group = {}
			--获得了道具的id
			if mydb_item_base_tbl[items_id]==nil then
				cclog("error:道具" .. items_id .."在表mydb_item_base_tbl中不存在" )
			else
				--获得道具的名称
				item_name = mydb_item_base_tbl[items_id].szName
				item_name_group = Tools_String("[" .. item_name .. "]")
				--获得道具的品质
				local quality = nil
				quality = mydb_item_base_tbl[items_id].nQuality
			end
			--铺设
			local CanBuildNum = GetStr_ToNextObject( item_name_group,Font_Size,Pos.x,SWidth)
			--创建对象
			local Str_Build = ""
			for i=1,CanBuildNum do
				Str_Build = Str_Build .. item_name_group[i]
			end
			--创建CanBuildNum相关
			if CanBuildNum<#item_name_group then
				--还有一部分没创建，再来一波
				local ThisWords=1+#Box_Font		
				Box_Font[ThisWords]=ccui.Text:create(Str_Build,"Arial",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				Box_Font[ThisWords]:setColor(cc.c3b(0,132,255))
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:ignoreContentAdaptWithSize(false)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				btns:setTag(items_id)
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					Rich_TextBox_Check_Item(sender:getTag())
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------
				if Font_Type==1 or Font_Type == 11 then --描边
					FUN_Shader_Font(Box_Font[ThisWords])
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.x = 0
				Pos.y = Pos.y + Font_Size + 4
				DuiQi_X_Form = ThisWords+1
				-----------------第二部分-------------------
				ThisWords=1+#Box_Font		
				------剩余部分-----
				local string_left = ""
				for i=CanBuildNum+1,#item_name_group do
					string_left = string_left .. item_name_group[i]
				end
				Box_Font[ThisWords]=ccui.Text:create(string_left,"Arial",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				Box_Font[ThisWords]:setColor(cc.c3b(0,132,255))
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:ignoreContentAdaptWithSize(false)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				btns:setTag(items_id)
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					Rich_TextBox_Check_Item(sender:getTag())
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------
				if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
				Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				--Box_Font[ThisWords]:enableUnderline()
				--Box_Font[ThisWords]:enableItalics()
				--Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 1 then --下划线
					Box_Font[ThisWords]:enableUnderline()
				end
				if math.floor(Font_Type/10) == 2 then --加粗
					Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 3 then --斜体
					Box_Font[ThisWords]:enableItalics()
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.height = Pos.y + Font_Size + 4
			else --创建完成！ 且没有换行
				local ThisWords=1+#Box_Font		
				Box_Font[ThisWords]=ccui.Text:create(Str_Build,"Arial",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				Box_Font[ThisWords]:setColor(cc.c3b(0,132,255))
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:ignoreContentAdaptWithSize(false)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				btns:setTag(items_id)
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					Rich_TextBox_Check_Item(sender:getTag())
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------				
				if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
				Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				--Box_Font[ThisWords]:enableUnderline()
				--Box_Font[ThisWords]:enableItalics()
				--Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 1 then --下划线
					Box_Font[ThisWords]:enableUnderline()
				end
				if math.floor(Font_Type/10) == 2 then --加粗
					Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 3 then --斜体
					Box_Font[ThisWords]:enableItalics()
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.height = Pos.y + Font_Size + 4
			end
		elseif ReturnDataString=="位置" then
			--找到
			ReturnDataString,Font_I=GetStringFormStruct(UTF8Words,Font_I)
			local position_info = SplitForInt(ReturnDataString,"-")
			local map_name = mydb_mapinfo_tbl[position_info[1]].MapName

			local map_name_group = {}
			--获得地图详细信息
			map_name_group = Tools_String("[" .. map_name .. "(" .. position_info[2] .. "," ..	position_info[3] .. ")]")

			--铺设
			local CanBuildNum = GetStr_ToNextObject( map_name_group,Font_Size,Pos.x,SWidth)
			--创建对象
			local Str_Build = ""
			for i=1,CanBuildNum do
				Str_Build = Str_Build .. map_name_group[i]
			end
			--创建CanBuildNum相关
			if CanBuildNum<#map_name_group then
				--还有一部分没创建，再来一波
				local ThisWords=1+#Box_Font		
				Box_Font[ThisWords]=ccui.Text:create(Str_Build,"Arial",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				if Split(ReturnDataString,"-")[5] == "help" then
					Box_Font[ThisWords]:setColor(cc.c3b(252,0,0))
				else
					Box_Font[ThisWords]:setColor(cc.c3b(0,132,255))
				end
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:ignoreContentAdaptWithSize(false)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				btns:setName(ReturnDataString)
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					local path_tbl = Split(sender:getName(),"-")
					Map_WaySearch(path_tbl[1],path_tbl[2],path_tbl[3],path_tbl[4],path_tbl[5],path_tbl[6])
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------
				if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
					Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				end
				if math.floor(Font_Type/10) == 1 then --下划线
					Box_Font[ThisWords]:enableUnderline()
				end
				if math.floor(Font_Type/10) == 2 then --加粗
					Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 3 then --斜体
					Box_Font[ThisWords]:enableItalics()
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.x = 0
				Pos.y = Pos.y + Font_Size + 4
				DuiQi_X_Form = ThisWords+1
				-----------------第二部分-------------------
				ThisWords=1+#Box_Font		
				------剩余部分-----
				local string_left = ""
				for i=CanBuildNum+1,#map_name_group do
					string_left = string_left .. map_name_group[i]
				end
				Box_Font[ThisWords]=ccui.Text:create(string_left,"Arial",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				if Split(ReturnDataString,"-")[5] == "help" then
					Box_Font[ThisWords]:setColor(cc.c3b(252,0,0))
				else
					Box_Font[ThisWords]:setColor(cc.c3b(0,132,255))
				end
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:ignoreContentAdaptWithSize(false)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				btns:setName(ReturnDataString)
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					local path_tbl = Split(sender:getName(),"-")
					Map_WaySearch(path_tbl[1],path_tbl[2],path_tbl[3],path_tbl[4],path_tbl[5],path_tbl[6])
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------

				if Font_Type==1 or Font_Type == 11 then --描边
					Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				end
				if Font_Type>=10 then --发光
					Box_Font[ThisWords]:enableGlow(cc.c4b(Font_r,Font_g,Font_b,Font_a))
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.height = Pos.y + Font_Size + 4
			else --创建完成！ 且没有换行
				local ThisWords=1+#Box_Font		
				Box_Font[ThisWords]=ccui.Text:create(Str_Build,"Arial",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				if Split(ReturnDataString,"-")[5] == "help" then
					Box_Font[ThisWords]:setColor(cc.c3b(252,0,0))
				else
					Box_Font[ThisWords]:setColor(cc.c3b(0,132,255))
				end
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:ignoreContentAdaptWithSize(false)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				btns:setName(ReturnDataString)
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					local path_tbl = Split(sender:getName(),"-")
					Map_WaySearch(path_tbl[1],path_tbl[2],path_tbl[3],path_tbl[4],path_tbl[5],path_tbl[6])
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------				

				if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
					Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				end
				if math.floor(Font_Type/10) == 1 then --下划线
					Box_Font[ThisWords]:enableUnderline()
				end
				if math.floor(Font_Type/10) == 2 then --加粗
					Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 3 then --斜体
					Box_Font[ThisWords]:enableItalics()
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.height = Pos.y + Font_Size + 4
			end
		elseif ReturnDataString=="图片" then
			--找到路径
			ReturnDataString,Font_I=GetStringFormStruct(UTF8Words,Font_I)
			--然后判断剩余空间是否足够插入，不足则换行插
			local ThisWords=1+#Box_Font		
			local ssa,ssb = string.find(ReturnDataString,",")
			if ssa==nil then
				ReturnDataString = ReturnDataString .. ",0,0"
			end
			local gorup_v =	 Split(ReturnDataString,",")
			local path_img = gorup_v[1]
			local arry_x = tonumber(gorup_v[2])
			local arry_y = tonumber(gorup_v[3])
			Box_Font[ThisWords]=getSprite(path_img)
			local img_size = Box_Font[ThisWords]:getContentSize()
			if Pos.x+img_size.width>SWidth then --塞不下去
				DuiQi_X_To = ThisWords - 1
				DuiQi_X()
				Pos.x = 0
				DuiQi_X_Form = ThisWords 
				if img_size.height>Font_Size+4 then
				Pos.y = Pos.y + img_size.height + 4
				else
				Pos.y = Pos.y + Font_Size + 4
				end
			end
			Box_Font[ThisWords]:setAnchorPoint(0.0,0.5)	 
			Box_Font[ThisWords]:setPositionX(Pos.x+arry_x)
			Box_Font[ThisWords]:setPositionY(-Pos.y+arry_y)
			Pos.height = Pos.y + Font_Size + 4
			Return_Layer:addChild(Box_Font[ThisWords])
			Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
			if Pos.width <Pos.x then Pos.width = Pos.x end
		elseif ReturnDataString=="动画" then
			--找到路径
			ReturnDataString,Font_I=GetStringFormStruct(UTF8Words,Font_I)
			--然后判断剩余空间是否足够插入，不足则换行插
			local ThisWords=1+#Box_Font		
			Box_Font[ThisWords]=load_Ani2D(ReturnDataString,-1)
			local img_size = Box_Font[ThisWords]:getChildByTag(1):getContentSize()
			---cclog("插入的动画" .. ReturnDataString .. "(" .. img_size.width .. "," .. img_size.height .. ")")
			if Pos.x+img_size.width>SWidth then --塞不下去
				DuiQi_X_To = ThisWords - 1
				DuiQi_X()
				Pos.x = 0
				DuiQi_X_Form = ThisWords 
				if img_size.height>Font_Size+4 then
				Pos.y = Pos.y + img_size.height + 4
				else
				Pos.y = Pos.y + Font_Size + 4
				end
			end
			Pos.height = Pos.y + Font_Size + 4
			Box_Font[ThisWords]:setAnchorPoint(0.5,0.5)	 
			Box_Font[ThisWords]:setPositionX(Pos.x+img_size.width/2)
			Box_Font[ThisWords]:setPositionY(-Pos.y)

			Return_Layer:addChild(Box_Font[ThisWords])
			Pos.x = Pos.x + img_size.width
			if Pos.width <Pos.x then Pos.width = Pos.x end
		elseif ReturnDataString=="函数" then
			--找到
			ReturnDataString,Font_I=GetStringFormStruct(UTF8Words,Font_I)
			--全部数据储存于ReturnDataString 格式为 funciotnType-showWords-value
			local String_tbl = Split(ReturnDataString,"-")
			local fun_name_group = {}
			fun_name_group = Tools_String("[" .. String_tbl[2] .. "]")
			local CanBuildNum = GetStr_ToNextObject( fun_name_group,Font_Size,Pos.x,SWidth)
			--创建对象
			local Str_Build = ""
			for i=1,CanBuildNum do
				Str_Build = Str_Build .. fun_name_group[i]
			end
			--创建CanBuildNum相关
			if CanBuildNum<#fun_name_group then
				--还有一部分没创建，再来一波
				local ThisWords=1+#Box_Font		
				Box_Font[ThisWords]=cc.Label:createWithTTF(Str_Build,"res/font/msyh.ttf",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				Box_Font[ThisWords]:setColor(cc.c4b(Font_r,Font_g,Font_b,Font_a))
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				--Box_Font[ThisWords]:setTouchEnabled(false)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:ignoreContentAdaptWithSize(false)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				local function hellowI(sender,eventType)
				if eventType ~= ccui.TouchEventType.ended then return end
				Rich_TextBox_Function(String_tbl[1],String_tbl[3])
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------

				if Font_Type==1 or Font_Type == 11 then --描边
				Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				end
				if Font_Type>=10 then --发光
				Box_Font[ThisWords]:enableGlow(cc.c4b(Font_r,Font_g,Font_b,Font_a))
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.x = 0
				Pos.y = Pos.y + Font_Size + 4
				DuiQi_X_Form = ThisWords+1
				-----------------第二部分-------------------
				ThisWords=1+#Box_Font		
				------剩余部分-----
				local string_left = ""
				for i=CanBuildNum+1,#fun_name_group do
				string_left = string_left .. fun_name_group[i]
				end
				Box_Font[ThisWords]=cc.Label:createWithTTF(string_left,"res/font/msyh.ttf",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				Box_Font[ThisWords]:setColor(cc.c3b(22,210,53))
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:ignoreContentAdaptWithSize(false)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				local function hellowI(sender,eventType)
				if eventType ~= ccui.TouchEventType.ended then return end
				Rich_TextBox_Function(String_tbl[1],String_tbl[3])
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------


				if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
				Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				--Box_Font[ThisWords]:enableUnderline()
				--Box_Font[ThisWords]:enableItalics()
				--Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 1 then --下划线
				Box_Font[ThisWords]:enableUnderline()
				end
				if math.floor(Font_Type/10) == 2 then --加粗
				Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 3 then --斜体
				Box_Font[ThisWords]:enableItalics()
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.height = Pos.y + Font_Size + 4
			else --创建完成！ 且没有换行
				local ThisWords=1+#Box_Font		
				Box_Font[ThisWords]=cc.Label:createWithTTF(Str_Build,"res/font/msyh.ttf",Font_Size)
				--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
				Box_Font[ThisWords]:setColor(cc.c4b(Font_r,Font_g,Font_b,Font_a))
				Box_Font[ThisWords]:setOpacity(Font_a)
				Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
				Box_Font[ThisWords]:setPositionX(Pos.x)
				Box_Font[ThisWords]:setPositionY(-Pos.y)
				------添加触摸事件-------
				local btns = ccui.Button:create()
				--btns:setCameraMask(cc.CameraFlag.USER1)
				btns:setAnchorPoint(0,0)
				btns:setPosition(0,0)
				btns:ignoreContentAdaptWithSize(false)
				btns:setSize(cc.size(Box_Font[ThisWords]:getContentSize().width,Font_Size+4))
				local function hellowI(sender,eventType)
					if eventType ~= ccui.TouchEventType.ended then return end
					Rich_TextBox_Function(String_tbl[1],String_tbl[3])
				end
				btns:addTouchEventListener(hellowI)
				Box_Font[ThisWords]:addChild(btns)
				-------------------------				
				if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
					Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
				end
				if math.floor(Font_Type/10) == 1 then --下划线
					Box_Font[ThisWords]:enableUnderline()
				end
				if math.floor(Font_Type/10) == 2 then --加粗
					Box_Font[ThisWords]:enableBold()
				end
				if math.floor(Font_Type/10) == 3 then --斜体
					Box_Font[ThisWords]:enableItalics()
				end
				Return_Layer:setTouchEnabled(false)
				Return_Layer:addChild(Box_Font[ThisWords])
				Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
				if Pos.width <Pos.x then Pos.width = Pos.x end
				Pos.height = Pos.y + Font_Size + 4
			end
		else--文本
			--一直读取到下一个结构体位置/要(主动/被动)换行的位置
			local TempWords,StopCode,StrNum = GetStr_ToNextStruct(UTF8Words,Font_I,Font_Size,Pos.x,SWidth)
			--cclog("富文本" .. text .. "解析结果:填充[" ..	TempWords .. "],类型 " .. StopCode .. ",字数=" .. StrNum )
			Font_I = Font_I + StrNum - 1 

			local ThisWords=1+#Box_Font		
			Box_Font[ThisWords]=cc.Label:createWithTTF(TempWords,"res/font/msyh.ttf",Font_Size)
			Box_Font[ThisWords]:setName("lbText")
			--Box_Font[ThisWords]:setCameraMask(cc.CameraFlag.USER1)
			Box_Font[ThisWords]:setTextColor(cc.c4b(Font_r,Font_g,Font_b,Font_a))
			Box_Font[ThisWords]:setAnchorPoint(0.0,1.0)			
			Box_Font[ThisWords]:setPositionX(Pos.x)
			Box_Font[ThisWords]:setPositionY(-Pos.y)
			if Font_Type - math.floor(Font_Type/10)*10==1	then --描边
				Box_Font[ThisWords]:enableOutline(cc.c4b(0,0,0,200),1)
			end
			if math.floor(Font_Type/10) == 1 then --下划线
				Box_Font[ThisWords]:enableUnderline()
			end
			if math.floor(Font_Type/10) == 2 then --加粗
				Box_Font[ThisWords]:enableBold()
			end
			if math.floor(Font_Type/10) == 3 then --斜体
				Box_Font[ThisWords]:enableItalics()
			end
			Return_Layer:setTouchEnabled(false)
			Return_Layer:addChild(Box_Font[ThisWords])
			Pos.x = Pos.x + Box_Font[ThisWords]:getContentSize().width
			if Pos.width <Pos.x then Pos.width = Pos.x end
			if StopCode==1 then --因为结构变动 or 到结尾
				Pos.height = Pos.y + Font_Size + 4
			elseif StopCode==2 then --主动换行
				--需要对齐
				DuiQi_X_To = ThisWords 
				DuiQi_X()
				Pos.x = 0
				Pos.y = Pos.y + Font_Size + 4
			elseif StopCode ==3 then --自动换行
				Pos.x = 0
				Pos.y = Pos.y + Font_Size + 4
				DuiQi_X_Form = ThisWords+1
			end
		end
	end
	--设置对齐
	DuiQi_X_To = #Box_Font	 
	DuiQi_X()
	--清空老数据
	Return_Layer:setTag(-1001)
	local LastOldL=layout:getChildByTag(-1001)
	if LastOldL~=nil then
		LastOldL:removeAllChildren()
		layout:removeChildByTag(-1001)
		LastOldL=nil
	end
	layout:addChild(Return_Layer)


	--cclog("[tips:]富文本：[" .. text .. "]	最终尺寸为" .. Pos.width .. "×" .. Pos.height)
	if Return_FullSize then
		return Pos.width,Pos.height,Box_Font
	else
		return Pos.height,nil,Box_Font
	end
end
----------触控event------------
--点击事件*不向下传递
function AddSingleTouchEvent(sender,fun)
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(fun,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:setSwallowTouches(false)
	local eventDispatcher = sender:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, sender)
end
--按住全部事件
function AddSingleEvent(sender,funStart,funMove,funEnd)
	local listener = cc.EventListenerTouchOneByOne:create()
	if funStart~=nil then listener:registerScriptHandler(funStart,cc.Handler.EVENT_TOUCH_BEGAN ) end
	if funMove~=nil then listener:registerScriptHandler(funMove,cc.Handler.EVENT_TOUCH_MOVED ) end
	if funEnd~=nil then listener:registerScriptHandler(funEnd,cc.Handler.EVENT_TOUCH_ENDED ) end 
	local eventDispatcher = sender:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, sender)
	return
end

-------------imageview的控制模式---
function addTouchEventListener(wid,fun,sender,isSwallow) 
	if isSwallow == nil then isSwallow = true end --如果为true会导致不触发上层Listview的滑动,设为false可保证上层控件的事件不受影响
	--print( isSwallow )
	local function touch_start(touch, event)
		local locationInNode = wid:convertToNodeSpace(touch:getLocation())
		local s
		if wid:getDescription() ~= "ImageView" then
			s = {width=99999,height=99999}; 
		else
			s = wid:getSize(); 
		end
		if (locationInNode.x>=0 and locationInNode.x<=s.width and locationInNode.y >=0 and	locationInNode.y<=s.height) then
			fun(sender,0, touch, event)
			return true;	
		else	
			return false;	 
		end
	end
	local function touch_move(touch, event)
		fun(sender,1,touch, event)
	end
	local function touch_end(touch, event)
		fun(sender,2,touch, event)
	end
	local function touch_cancelled(touch, event)
		fun(sender,3,touch, event)
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(isSwallow)
	listener:registerScriptHandler(touch_start,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(touch_move,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(touch_end,cc.Handler.EVENT_TOUCH_ENDED )
	listener:registerScriptHandler(touch_cancelled,cc.Handler.EVENT_TOUCH_CANCELLED )
	local eventDispatcher = wid:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener,wid)
end
--------------WinTitle模式----------
function Add_Touch_Drag(wid)
	local Record_x = 0
	local Record_y = 0
	local BaseLPx=0
	local BaseLPy=0
	local function WayMove(touch,event) 
		local endLocation = touch:getLocation()
		wid:setPositionX(BaseLPx+endLocation.x-Record_x)
		wid:setPositionY(BaseLPy+endLocation.y-Record_y)
		return
	end

	local function WayEnd(touch,event)
		return
	end
	local function WaySet(touch,event)	
		local endLocation = touch:getLocation()
		local wid_w = wid:getSize().width
		local wid_H = wid:getSize().height
		-- cclog("touchin=" ..endLocation.x .. "," .. endLocation.y )
		-- cclog("	widin=" .. wid:getWorldPosition().x .. "," .. wid:getWorldPosition().y)
		-- cclog("	size =" .. wid_w .. "," .. wid_H)
		if endLocation.x <	wid:getWorldPosition().x then return end
		if endLocation.y <	wid:getWorldPosition().y then return end
		if endLocation.x >	wid:getWorldPosition().x+wid_w then return end
		if endLocation.y >	wid:getWorldPosition().y+wid_H then return end
		Record_x = endLocation.x
		Record_y = endLocation.y
		BaseLPx = wid:getPositionX() 
		BaseLPy = wid:getPositionY()
		return true
	end
	AddSingleEvent(wid,WaySet,WayMove,WayEnd)
end