Use_ListForFastRun = true --执行链表的快速储存技术
Use_FasterFindWid = true
UIName_2_UILayer_Table = {}
-- 这是两层表，第一层ui名到第二层表，第二层tag到position表
UIName_2_Position_Table_Table = {}

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

--------------复制table
function table_copy_table(ori_tab)
	if (type(ori_tab) ~= "table") then
			return nil
	end
	local new_tab = {}
	for i,v in pairs(ori_tab) do
		local vtyp = type(v)
		if (vtyp == "table") then
				new_tab[i] = table_copy_table(v)
		elseif (vtyp == "thread") then
				new_tab[i] = v
		elseif (vtyp == "userdata") then
				new_tab[i] = v
		else
				new_tab[i] = v
		end
	end
	return new_tab
end

-------------------------UI载入系统---------------------------
local function MMR_FindFather(Layer,UI_Name,i) --内部使用，用于返回指定控件的父控件
	local NameTag = {} --储存name链

	if UI_Layout_Config[UI_Name].Sprite[i].Parent == 1 then
		return Layer
	end
	
	local function DiGuiFindFatherIndexByID(Parent) --找到
		--找到父的Name
		for s=1,UI_Layout_Config[UI_Name].SpriteCount do
			if UI_Layout_Config[UI_Name].Sprite[s].SingleID == Parent then
				--Name得到 s得到
				NameTag[1+#NameTag] = UI_Layout_Config[UI_Name].Sprite[s].Name
				DiGuiFindFatherIndexByID(UI_Layout_Config[UI_Name].Sprite[s].Parent)
			end
		end
	end
	DiGuiFindFatherIndexByID(UI_Layout_Config[UI_Name].Sprite[i].Parent)
	local Widght = Layer 
	--cclog("MMR_FindFather = " .. #NameTag)
	for q=1,#NameTag do
		--cclog("查找：" .. NameTag[#NameTag+1-q])
		if Widght:getChildByName(NameTag[#NameTag+1-q])~= nil then
			Widght = Widght:getChildByName(NameTag[#NameTag+1-q])
		end
	end

	return Widght
end


--UI系统的链表结构
local p_UI_List = {
	-- [plaout] = 
	--					{
	--						RetainLayer = nil,
	--						Name = "UI_Name",
	--						Type = 0,--为1表示是list元素
	--						Group = {
	--												[tag] = fatherTag,
	--										}
	--					}
} 

--加载UI文件，UI_Name 文件名称
--				*MuitlThread 可选项，是否通过C++加载（复杂功能情况下不推荐）
--				在UI界面短小时，启动MuitThread通常更快
function CLS_p_UI_List()
	p_UI_List = nil
	p_UI_List = {}
end
function LoadUI(UI_Name,MuitlThread)
	local start = server.clock()
	--定义主层
	local Layer =nil
	--需要保存链表的
	local NeedSaveList = true
	--检查是否是元素层* 
	local ItemLayout = UI_Layout_Config[UI_Name].Mutex
	--创建
	for i=1,UI_Layout_Config[UI_Name].SpriteCount do
		--cclog("新UI：正在创建第" .. i	.. "个控件" .. UI_Layout_Config[UI_Name].Sprite[i].Name)
		local newUI = table_copy_table(UI_Layout_Config[UI_Name].Sprite[i])
		--------------创建layer
		if newUI.Type == 0 then
			if Layer==nil then
				local function createLayerFunc( ... )
					local ret = ccui.Layout:create()
					local size = {1334,750}
					ret:setContentSize(size)
					ret:setPositionX(UtiltityTool.VisibleSize.width/2 -1334/2)
					ret:setName(newUI.Name)
					ret:setTag(newUI.Tag)
					if newUI.Visible~="True" then ret:setVisible(false) end
					if newUI.Enable~="True" then ret:setTouchEnabled(false) end			
					--创建遮罩
					if UI_Layout_Config[UI_Name].WithBg == 1 then
						local ZZ = ccui.ImageView:create("res/UIEditor/GUI/zhezhao2.png")
						ZZ:setScaleX(UtiltityTool.VisibleSize.width/144)
						ZZ:setScaleY(UtiltityTool.VisibleSize.height/64)
						ZZ:setAnchorPoint(0.5,0.5)
						ZZ:setPosition(UtiltityTool.VisibleSize.width/2,UtiltityTool.VisibleSize.height/2)
						ZZ:setOpacity(204)
						ZZ:setTouchEnabled(true)
						ZZ:setTag(99999)
						ret:addChild(ZZ)
					end
					return ret
				end
				Layer = createLayerFunc()
				--Layer:retain()
				Layer.cloneFunc = createLayerFunc
				if Use_ListForFastRun then
								--储存链表
								for k,v in pairs(p_UI_List) do
									if v.Name == UI_Name then
											NeedClsList = true
											p_UI_List[tostring(Layer)] = p_UI_List[k]
											break
									end
								end
								if p_UI_List[tostring(Layer)]==nil then
									p_UI_List[tostring(Layer)] = {
																									RetainLayer = Layer,
																									Name = UI_Name,
																									Type = ItemLayout,
																									Group = {},
																								}
								end
				end
			else
				print("创建错误：不能多个层")
			end
		end
		--------------创建图片控件
		if newUI.Type == 1 then
				if newUI.ImgPathA ~= "" then
						local img 
						if string.find(newUI.Name, "SPRITE") then
							img = cc.Sprite:create(); 
						else
							img = ccui.ImageView:create(); 
						end
						if img==nil then
								print("创建失败：" .. "res/" .. newUI.ImgPathA)
						else
								local function initImageLayer( imgLayer )
									if string.find(newUI.Name, "SPRITE") then
										imgLayer:setTexture("res/" .. newUI.ImgPathA)
									else
										imgLayer:setScale9Enabled(false)
										imgLayer:loadTexture("res/" .. newUI.ImgPathA)
										imgLayer:setName(newUI.Name)
									end
									imgLayer:setTag(newUI.Tag)
									if newUI.Visible~="True" then imgLayer:setVisible(false) end
									if newUI.Enable~="True" then imgLayer:setTouchEnabled(false) end
									imgLayer:setAnchorPoint(cc.p(0, 0))
									--如果它的parent == 1说明是第一级控件 根据模式调整坐标
									if newUI.Parent == 1 then
										if newUI.LayoutMode == 1 then --左下角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 3 then --右下角
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 5 then --中
											if UI_Layout_Config[UI_Name].Mutex==0 then
												newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)/2
											end
										elseif newUI.LayoutMode == 7 then --左上角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										elseif newUI.LayoutMode == 9 then --右上角
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										end
									end
									imgLayer:setPosition(newUI.posX,newUI.posY)
									imgLayer:setLocalZOrder(newUI.Zorder)
								end
								initImageLayer(img)
								img.cloneFunc = function( ... )
									local ret = ccui.ImageView:create()
									initImageLayer(ret)
									return ret
								end
								
								--如果是元素页面需要调整参数
								if ItemLayout>0 then
									ItemLayout=0
									Layer:setContentSize(cc.size(newUI.Width,newUI.Height))
									Layer:setPositionX(0)
								end
								--DragAble
								if newUI.Text == "DragAble" then
									Add_Touch_Drag(img)
								end
								--找img的父是谁，依此递归下去
								local father = MMR_FindFather(Layer,UI_Name,i)
								father:addChild(img)
								if NeedSaveList and Use_ListForFastRun then
									p_UI_List[tostring(Layer)].Group[newUI.Tag] = father:getTag()
								end
						end
				end
		end
		------------创建btn控件
		if newUI.Type == 2 then
				if newUI.ImgPathA ~= "" then
						local img = nil
						if string.find(newUI.Name, "CUSTOM") then
							img = CustomButton:create("res/" .. newUI.ImgPathA)
						else
							img = ccui.Button:create("res/" .. newUI.ImgPathA)
						end
	
						if img==nil then
								print("创建失败：" .. "res/" .. newUI.ImgPathA)
						else
								local function initButtonLayer( imgLayer )
									if newUI.ImgPathB~="" then
										if newUI.ImgPathB~="UIEditor/GUI/image.png" then
											imgLayer:loadTexturePressed("res/" .. newUI.ImgPathB)
										end											
									end
									imgLayer:setName(newUI.Name)
									imgLayer:setTag(newUI.Tag)
									if newUI.Visible~="True" then imgLayer:setVisible(false) end
									if newUI.Enable~="True" then imgLayer:setTouchEnabled(false) end
									imgLayer:setAnchorPoint(cc.p(0, 0))
									--如果它的parent == 1说明是第一级控件 根据模式调整坐标
									if newUI.Parent == 1 then
										if newUI.LayoutMode == 1 then --左下角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 3 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 5 then --
											if UI_Layout_Config[UI_Name].Mutex==0 then
												newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)/2
											end
										elseif newUI.LayoutMode == 7 then --
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										elseif newUI.LayoutMode == 9 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										end
									end
									imgLayer:setPosition(newUI.posX,newUI.posY)
									imgLayer:setLocalZOrder(newUI.Zorder)
								end

								initButtonLayer(img)
								if string.find(newUI.Name, "CUSTOM") then
									img.cloneFunc = function()
										local ret =
										CustomButton:create("res/" .. newUI.ImgPathA)
										initButtonLayer(ret)
										return ret
									end
								else
									img.cloneFunc = function()
										local ret = ccui.Button:create("res/" .. newUI.ImgPathA)
										initButtonLayer(ret)
										return ret
									end
								end
								
								--如果是元素页面需要调整参数
								if ItemLayout>0 then
									ItemLayout=0
									Layer:setContentSize(cc.size(newUI.Width,newUI.Height))
									Layer:setPositionX(0)
								end
								--找img的父是谁，依此递归下去
								local father = MMR_FindFather(Layer,UI_Name,i)
								father:addChild(img)
								if NeedSaveList	and Use_ListForFastRun then
									p_UI_List[tostring(Layer)].Group[newUI.Tag] = father:getTag()
								end
						end
				end
		end
		-------------创建listView控件		3 
		if newUI.Type == 3 then
				if newUI.ImgPathA ~= "" then
						local img = ccui.ListView:create(); 
						if img==nil then
								print("创建失败：" .. "res/" .. newUI.ImgPathA)
						else
								local function initListView(imgLayer)
									imgLayer:setName(newUI.Name)
									imgLayer:setTag(newUI.Tag)
									imgLayer:setBounceEnabled(true)
									imgLayer:setBackGroundImage("res/UIEditor/GUI/listviewbox.png")
									imgLayer:setAnchorPoint(cc.p(0, 0))
									imgLayer:setBackGroundImageScale9Enabled(true)
									imgLayer:setContentSize(cc.size(newUI.Width,newUI.Height))
									imgLayer:setContentSize(cc.size(newUI.Width,newUI.Height))
									if newUI.Visible~="True" then imgLayer:setVisible(false) end
									if newUI.Enable~="True" then imgLayer:setTouchEnabled(false) end
									--如果它的parent == 1说明是第一级控件 根据模式调整坐标
									if newUI.Parent == 1 then
										if newUI.LayoutMode == 1 then --左下角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 3 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 5 then --
											if UI_Layout_Config[UI_Name].Mutex==0 then
												newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)/2
											end
										elseif newUI.LayoutMode == 7 then --
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										elseif newUI.LayoutMode == 9 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										end
									end
									imgLayer:setPosition(newUI.posX,newUI.posY)
									imgLayer:setLocalZOrder(newUI.Zorder)
								end

								initListView(img)
								img.cloneFunc = function ()
									local ret = ccui.ListView:create()
									initListView(ret)
									return ret
								end
								
								--如果是元素页面需要调整参数
								if ItemLayout>0 then
									ItemLayout=0
									Layer:setContentSize(cc.size(newUI.Width,newUI.Height))
									Layer:setPositionX(0)
								end
								--找img的父是谁，依此递归下去
								local father = MMR_FindFather(Layer,UI_Name,i)
								father:addChild(img)
								if NeedSaveList	and Use_ListForFastRun then
									p_UI_List[tostring(Layer)].Group[newUI.Tag] = father:getTag()
								end
						end
				end
		end
		-------------创建NumberLabel控件	4
		if newUI.Type == 4 then
				if newUI.ImgPathA ~= "" then
						local img = ccui.TextAtlas:create("0","res/" .. newUI.ImgPathA,newUI.Width/10,newUI.Height,"0"); 
						if img==nil then
								print("创建失败：" .. "res/" .. newUI.ImgPathA)
						else
								local function initNumberLabel(imgLayer)
									imgLayer:setName(newUI.Name)
									imgLayer:setTag(newUI.Tag)
									if newUI.Visible~="True" then imgLayer:setVisible(false) end
									if newUI.Enable~="True" then imgLayer:setTouchEnabled(false) end
									imgLayer:setAnchorPoint(cc.p(0, 0))
									--如果它的parent == 1说明是第一级控件 根据模式调整坐标
									if newUI.Parent == 1 then
										if newUI.LayoutMode == 1 then --左下角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 3 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 5 then --
											if UI_Layout_Config[UI_Name].Mutex==0 then
												newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)/2
											end
										elseif newUI.LayoutMode == 7 then --
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										elseif newUI.LayoutMode == 9 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										end
									end
									imgLayer:setPosition(newUI.posX,newUI.posY)
									imgLayer:setLocalZOrder(newUI.Zorder)
								end
								initNumberLabel(img)
								img.cloneFunc = function ()
									local ret = ccui.TextAtlas:create("0","res/" .. newUI.ImgPathA,newUI.Width/10,newUI.Height,"0")
									initNumberLabel(ret)
									return ret
								end
								
								--如果是元素页面需要调整参数
								if ItemLayout>0 then
									ItemLayout=0
									Layer:setContentSize(cc.size(newUI.Width,newUI.Height))
									Layer:setPositionX(0)
								end
								--找img的父是谁，依此递归下去
								local father = MMR_FindFather(Layer,UI_Name,i)
								father:addChild(img)
								if NeedSaveList	and Use_ListForFastRun then
									p_UI_List[tostring(Layer)].Group[newUI.Tag] = father:getTag()
								end
						end
				end
		end
		-------------创建InputBox控件	5				
		if newUI.Type == 5 then
				if newUI.ImgPathA ~= "" then							
						local img = cc.EditBox:create(cc.size(newUI.Width,newUI.Height),cc.Scale9Sprite:create(cc.rect(0,0,newUI.Width,newUI.Height),"res/" .. newUI.ImgPathA))
						img:setInputFlag(1)
						img:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
						if img==nil then
								print("创建失败：" .. "res/" .. newUI.ImgPathA)
						else
								local function initInputBox(imgLayer)
									--imgLayer:setName(newUI.Name)
									imgLayer:setTag(newUI.Tag)
									if newUI.Visible~="True" then imgLayer:setVisible(false) end
									if newUI.Enable~="True" then imgLayer:setTouchEnabled(false) end
									imgLayer:setAnchorPoint(cc.p(0, 0))
									--如果它的parent == 1说明是第一级控件 根据模式调整坐标
									if newUI.Parent == 1 then
										if newUI.LayoutMode == 1 then --左下角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 3 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 5 then --
											if UI_Layout_Config[UI_Name].Mutex==0 then
												newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)/2
											end
										elseif newUI.LayoutMode == 7 then --
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										elseif newUI.LayoutMode == 9 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										end
									end
									imgLayer:setPosition(newUI.posX,newUI.posY)
									imgLayer:setLocalZOrder(newUI.Zorder)
								end
								initInputBox(img)
								img.cloneFunc = function ( ... )
									local ret = cc.EditBox:create(cc.size(newUI.Width,newUI.Height),cc.Scale9Sprite:create(cc.rect(0,0,newUI.Width,newUI.Height),"res/" .. newUI.ImgPathA))
									initInputBox(ret)
									return ret
								end
								
								--如果是元素页面需要调整参数
								if ItemLayout>0 then
									ItemLayout=0
									Layer:setContentSize(cc.size(newUI.Width,newUI.Height))
									Layer:setPositionX(0)
								end
								--找img的父是谁，依此递归下去
								local father = MMR_FindFather(Layer,UI_Name,i)
								father:addChild(img)
								if NeedSaveList	and Use_ListForFastRun then
									p_UI_List[tostring(Layer)].Group[newUI.Tag] = father:getTag()
								end
						end
				end
		end
		-------------创建Label控件			6【富文本/文本】	--已经支持
		if newUI.Type == 6 then
				if newUI.ImgPathA ~= "" then
						local img
						if newUI.ListViewMode== 0 then
							img = ccui.Text:create("","Arial",1); 
							img:setContentSize(cc.size(newUI.Width,newUI.Height))
							img:setContentSize(cc.size(newUI.Width,newUI.Height))
							img:setAnchorPoint(cc.p(0, 1))
							--MMR_EditRichText_Plus(img,newUI.Text,nil,nil,nil,nil,newUI.Width)
						else
							img = ccui.Text:create(newUI.Text,"Arial",newUI.Height); 
							img:setColor(cc.c3b(tonumber(newUI.ImgPathA),tonumber(newUI.ImgPathB),tonumber(newUI.ImgPathC)))
							img:setContentSize(cc.size(newUI.Width,newUI.Height+4))
							img:setContentSize(cc.size(newUI.Width,newUI.Height+4))
							img:setAnchorPoint(cc.p(0, 1))
						end
						if img==nil then
								print("创建失败：" .. "res/" .. newUI.ImgPathA)
						else
								local function initLabel(imgLayer)
									imgLayer:setName(newUI.Name)
									imgLayer:setTag(newUI.Tag)
									if newUI.Visible~="True" then imgLayer:setVisible(false) end
									if newUI.Enable~="True" then imgLayer:setTouchEnabled(false) end
									--如果它的parent == 1说明是第一级控件 根据模式调整坐标
									if newUI.Parent == 1 then
										if newUI.LayoutMode == 1 then --左下角
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 3 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
										elseif newUI.LayoutMode == 5 then --
											if UI_Layout_Config[UI_Name].Mutex==0 then
												newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)/2
											end
										elseif newUI.LayoutMode == 7 then --
											newUI.posX = newUI.posX -(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										elseif newUI.LayoutMode == 9 then --
											newUI.posX = newUI.posX +(UtiltityTool.VisibleSize.width/2 -1334/2)
											newUI.posY = newUI.posY +(UtiltityTool.VisibleSize.height -750)
										end
									end
									imgLayer:setPosition(newUI.posX,newUI.posY)
									imgLayer:setLocalZOrder(newUI.Zorder)
								end
								initLabel(img)
								if newUI.ListViewMode== 0 then
									img.cloneFunc = function()
										local ret =
										ccui.Text:create("","Arial",1); 
										ret:setContentSize(cc.size(newUI.Width,newUI.Height))
										ret:setContentSize(cc.size(newUI.Width,newUI.Height))
										ret:setAnchorPoint(cc.p(0, 1))
										initLabel(ret)
										return ret
									end
									--MMR_EditRichText_Plus(img,newUI.Text,nil,nil,nil,nil,newUI.Width)
								else
									img.cloneFunc = function()
										local ret =
										ccui.Text:create(newUI.Text,"Arial",newUI.Height); 
										ret:setColor(cc.c3b(tonumber(newUI.ImgPathA),tonumber(newUI.ImgPathB),tonumber(newUI.ImgPathC)))
										ret:setContentSize(cc.size(newUI.Width,newUI.Height+4))
										ret:setContentSize(cc.size(newUI.Width,newUI.Height+4))
										ret:setAnchorPoint(cc.p(0, 1))
										initLabel(ret)
										return ret
									end
								end
								
								--如果是元素页面需要调整参数
								if ItemLayout>0 then
									ItemLayout=0
									Layer:setContentSize(cc.size(newUI.Width,newUI.Height))
									Layer:setPositionX(0)
								end
								--找img的父是谁，依此递归下去
								local father = MMR_FindFather(Layer,UI_Name,i)
								father:addChild(img)
								if NeedSaveList	and Use_ListForFastRun then
									p_UI_List[tostring(Layer)].Group[newUI.Tag] = father:getTag()
								end
						end
				end
		end
		-------------创建CheckBox控件		7
	end
	print("[tips:]LoadUI：" .. UI_Name .. "消耗时间 %.5f",server.clock() - start)
	UIName_2_UILayer_Table[UI_Name] = Layer
	UIName_2_Position_Table_Table[UI_Name] = {}
	return Layer
end


local WidPool = {} --结构 地址 + tag标记符 + ...
local FasterWidSaveName = nil
local ComboLowSerchTimes = 0 --连续1次低效率搜索就要改变设置了！
--查询UI控件*如果已经找到过就直接返回 *填写UIName将提高索引速度	*CLSSavedName填写它将进行精确搜索
function FindWidByTag(sender,tag,UIName,CLSSavedName,debug)
	if sender==nil then return end 
	if Use_ListForFastRun ==false then
		local allchild=sender:getChildren()
		for k,v in pairs(allchild) do
			if v:getTag() == tag then return v end
			for k1,v1 in pairs(v:getChildren()) do
				if v1:getTag() == tag then return v1 end
				for k2,v2 in pairs(v1:getChildren()) do
					if v2:getTag() == tag then return v2 end
					for k3,v3 in pairs(v2:getChildren()) do
						if v3:getTag() == tag then return v3 end
						for k4,v4 in pairs(v3:getChildren()) do
							if v4:getTag() == tag then return v4 end
							for k5,v5 in pairs(v4:getChildren()) do
								if v5:getTag() == tag then return v5 end
								for k6,v6 in pairs(v5:getChildren()) do
									if v6:getTag() == tag then return v6 end
									for k7,v7 in pairs(v6:getChildren()) do
										if v7:getTag() == tag then return v7 end
										for k8,v8 in pairs(v7:getChildren()) do
											if v8:getTag() == tag then return v8 end
											for k9,v9 in pairs(v8:getChildren()) do
												if v9:getTag() == tag then return v9 end
												for k10,v10 in pairs(v9:getChildren()) do
													if v10:getTag() == tag then return v10 end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end			
		return nil
	end
	local p_UI_Wid = tostring(sender)

	if ComboLowSerchTimes>=1 then
		ComboLowSerchTimes=0
		--强制检索资源
		cclog("WSARNING:启动强制检索资源")
		for k,v in pairs(p_UI_List) do
			if v.Type~= 0 then
				for k1,v1 in pairs(v.Group) do
					if k1==tag then
						UIName = v.Name
						cclog("WSARNING:强制检索资源成功" .. UIName)
						break
					end
				end
			end
		end
	end

	-------测试
	local Faseradsd = false 
	if UIName==nil and FasterWidSaveName~=nil then
		Faseradsd=true
	end
	-------测试

	if CLSSavedName ==true then FasterWidSaveName= nil end


	if UIName==nil then
		UIName = FasterWidSaveName
	else
		FasterWidSaveName=UIName
	end


	---*检查是否有克隆对象
	if UIName~= nil then
			for k,v in pairs(p_UI_List) do
				if v.Type~=0 then
					if v.Name == UIName then
						p_UI_Wid = k
						if Faseradsd then
							--cclog("从克隆体找到对象！" .. UIName)
							if v.Group[tag]==nil then
										print("WARNING:启用上次搜索的" .. FasterWidSaveName .. "失败了,重新搜索")
										FasterWidSaveName = nil
										return FindWidByTag(sender,tag,nil,nil,true)
							end
						end
						break
					end
				end
			end
	end

	if p_UI_List[p_UI_Wid]~=nil and Use_FasterFindWid then
		local WidList = {tag,}
		local Tmp = tag

		for i=1,10 do
			if p_UI_List[p_UI_Wid].Group[Tmp]==1 then break end
			WidList[#WidList+1] = p_UI_List[p_UI_Wid].Group[Tmp] 
			Tmp = WidList[#WidList]
		end

		local wid = sender
		for i=#WidList,1,-1 do
			wid=wid:getChildByTag(WidList[i])
		end
		ComboLowSerchTimes = 0
		if debug==true then 
			print("WARNING:最终搜索到" .. p_UI_List[p_UI_Wid].Name .. "的" .. tag)
		end
		return wid
	else
		if Use_FasterFindWid then
			FasterWidSaveName = nil
			if WidPool[tostring(sender)]~=nil then
				if WidPool[tostring(sender)][tag]~=nil then
					local wid = sender
					local CheckTag = 0
					for i=1,#WidPool[tostring(sender)][tag] do
						CheckTag=WidPool[tostring(sender)][tag][i]
						if wid==nil then WidPool[tostring(sender)] = {} return FindWidByTag(sender,tag) end
						if tag==CheckTag then return wid:getChildByTag(CheckTag) end
						wid=wid:getChildByTag(CheckTag)
					end
					ComboLowSerchTimes = 0
					return wid
				end
			end
		end
			if WidPool[tostring(sender)]==nil then
				WidPool[tostring(sender)] = {}
			end
		-- ------逐层遍历而不是用根部遍历
		-- local allchild=sender:getChildren()

		-- local list = {}
		-- for k,v in pairs(allchild) do
		--	if v:getTag() == tag then return v end
		--	list[#list+1] = v
		-- end

		-- for k,v in pairs(allchild) do
		--	for k1,v1 in pairs(v:getChildren()) do
				
				
		--	end
		-- end
		print("WASRNING:使用原始FWD查询" .. tag)
		ComboLowSerchTimes = ComboLowSerchTimes +1
		local list= {}
		local allchild=sender:getChildren()
		for k,v in pairs(allchild) do
			list[1] = v:getTag()
			if list[1] == tag then WidPool[tostring(sender)][tag] =list return v end
			for k1,v1 in pairs(v:getChildren()) do
				list[2] = v1:getTag()
				if v1:getTag() == tag then WidPool[tostring(sender)][tag] =list return v1 end
				for k2,v2 in pairs(v1:getChildren()) do
					list[3] = v2:getTag()
					if v2:getTag() == tag then WidPool[tostring(sender)][tag] =list return v2 end
					for k3,v3 in pairs(v2:getChildren()) do
						list[4] = v3:getTag()
						if v3:getTag() == tag then WidPool[tostring(sender)][tag] =list return v3 end
						for k4,v4 in pairs(v3:getChildren()) do
							list[5] = v4:getTag()
							if v4:getTag() == tag then WidPool[tostring(sender)][tag] =list return v4 end
							for k5,v5 in pairs(v4:getChildren()) do
								list[6] = v5:getTag()
								if v5:getTag() == tag then WidPool[tostring(sender)][tag] =list return v5 end
								for k6,v6 in pairs(v5:getChildren()) do
									list[7] = v6:getTag()
									if v6:getTag() == tag then WidPool[tostring(sender)][tag] =list return v6 end
									for k7,v7 in pairs(v6:getChildren()) do
										list[8] = v7:getTag()
										if v7:getTag() == tag then WidPool[tostring(sender)][tag] =list return v7 end
										for k8,v8 in pairs(v7:getChildren()) do
											list[9] = v8:getTag()
											if v8:getTag() == tag then WidPool[tostring(sender)][tag] =list return v8 end
											for k9,v9 in pairs(v8:getChildren()) do
											list[10] = v9:getTag()
												if v9:getTag() == tag then WidPool[tostring(sender)][tag] =list return v9 end
												for k10,v10 in pairs(v9:getChildren()) do
													list[11] = v10:getTag()
													if v10:getTag() == tag then WidPool[tostring(sender)][tag] =list return v10 end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end			
		cclog("WARNING:没有找到匹配的Tag控件（十层搜索了CNM！）"..tag)
	end
end

--add by hujie(根据名字搜索某控件。)
function FindWidgetByName( sender, name )
		if sender:getName() == name then return sender end
		for k,v in pairs(sender:getChildren()) do
				local fuck = FindWidgetByName( v, name )
				if fuck ~= nil then
						return fuck
				else
						
				end
		end
		return nil
end

--PushUI的层级 部分明确标识
-- 弹幕								9999
-- 游戏登陆						999
-- 剧情副本胜利结算面板 7


function PushUI(layer,Zorder, alignCenter)
	if layer ==nil then return end
	if Zorder~=nil then layer:setLocalZOrder(Zorder) end
	G_UILayer:addChild(layer)
end

function ChangeAnchor(sender,pointX,pointY)
	local point = cc.p(pointX,pointY)
	local oldAnchor = sender:getAnchorPoint()
	local WidWidth = sender:getSize().width
	local WidHeight = sender:getSize().height
	local oldPos = {x=sender:getPositionX()-WidWidth*oldAnchor.x,y=sender:getPositionY()-WidHeight*oldAnchor.y}
	sender:setAnchorPoint(point)
	sender:setPosition(oldPos.x+point.x*WidWidth ,oldPos.y+point.y*WidHeight )
end


----储存/覆盖本地数据
--types: 0公共数据	1个人账户数据
--FitStr: 属性字段名
--Val:字段值 字符串类型
function P_Save_Local_Data(types,FitStr,Val)
	if types==0 then
		cc.UserDefault:getInstance():setStringForKey(FitStr, Val)
	else
		local accountText = cc.UserDefault:getInstance():getStringForKey("account")
		cc.UserDefault:getInstance():setStringForKey( accountText .. "_" .. FitStr, Val)		
	end
end
function P_Load_Local_Data(types,FitStr)
	if types==0 then
		return cc.UserDefault:getInstance():getStringForKey(FitStr)
	else
		local accountText = cc.UserDefault:getInstance():getStringForKey("account")
		return cc.UserDefault:getInstance():getStringForKey( accountText .. "_" .. FitStr)		
	end
end

if kTargetWindows == CCApplication:getInstance():getTargetPlatform() then
	local savedfun2a = require
	--require = nil
	require = function (...)
			--print("dorequire----" ..name)
			local a,b = string.find(...,"src/")
			if a~=nil then
				package.loaded[...] = nil
			else
				a,b = string.find(...,"res/")
				if a~=nil then
					package.loaded[...] = nil
				end
			end
			return savedfun2a(...)
	end
end

