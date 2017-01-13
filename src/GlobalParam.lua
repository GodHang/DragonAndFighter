--此文件保存游戏全局变量 2016年11月9日 15:02:16 刘一杭

--游戏主场景
G_GameScene = {}

--[[
	地图层		  ：G_MapLayer     1 	【地形/建筑/人物/场景上的特效处于此层级】·禁用！
	主面板UI层	  ：G_MainUILayer  2	【技能按钮、主游戏菜单界面】
	弹出的UI层    ：G_UILayer      3	【其他子界面】·PushUI()
	消息提示层    ：G_MsgLayer	 4		【弹出的消息】`pushMsg()
--]]
G_MapLayer = {}
G_MainUILayer = {}
G_UILayer = {}
G_MsgLayer = {}

--全局定时器
scheduler = cc.Director:getInstance():getScheduler()