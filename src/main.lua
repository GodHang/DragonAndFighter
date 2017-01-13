
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local function checkUpdate()	
end

local function main()
	require("src/GameInit")
	require("src/Global")
	require("res/UI_Layout_Config")

	G_GameScene = display.newScene("MainView")
	display.runScene(G_GameScene)

	G_MapLayer = cc.Layer:create()
	G_MapLayer:setLocalZOrder(1)
	G_GameScene:addChild(G_MapLayer)

	G_MainUILayer = cc.Layer:create()
	G_MainUILayer:setLocalZOrder(2)
	G_GameScene:addChild(G_MainUILayer)

	G_UILayer = cc.Layer:create()
	G_UILayer:setLocalZOrder(3)
	G_GameScene:addChild(G_UILayer)

	G_MsgLayer = cc.Layer:create()
	G_MsgLayer:setLocalZOrder(4)
	G_GameScene:addChild(G_MsgLayer)

	checkUpdate()

	local s = display.newSprite("res/img/HelloWorld.png",200,200)
	G_MapLayer:addChild(s)

	for i=1,10 do
		print("测试测试测试")
	end

	PushUI()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
