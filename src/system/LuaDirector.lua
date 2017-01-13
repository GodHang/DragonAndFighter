LuaDirector = class("LuaDirector")

function LuaDirector:ctor()
	--map<int msgid, function(Smessage *)>
	self.msg_handler_map = {}
end

local function temp_msg_handler(msg)
	LuaDirector.instance:msg_handler(msg)
end

function LuaDirector:init()
	GameDirector:getInstance():register_lua_msg_handler(temp_msg_handler)
end

--void(int,function<Smessage> )
function LuaDirector:register_lua_msg(msg_id,deal_func)
	--assert(self.msg_handler_map[msg_id] == nil, "处理ID重复")
	if deal_func==nil then
		cclog("error:消息" .. (msg_id % 256) .. "-" .. math.floor(msg_id / 256) .. "注册失败！函数为空")
	end
	self.msg_handler_map[msg_id] = deal_func
end

function LuaDirector:unregister_msg( msg_id )
	self.msg_handler_map[msg_id] = nil
end

function LuaDirector:has_registerd(msg_id)
	if(self.msg_handler_map[msg_id] == nil) then
		return false
	else
		return true
	end
end
-------------------------------------------------------

function DoGROUPLISTDATA()
		for i=1,#MsgGROUP_DATA do
			local msg = MSG.new()
			msg:setdata(MsgGROUP_DATA[i].id,MsgGROUP_DATA[i].msg)
			local msg_id = msg:get_msg_id()
    		--print( string.format( "error:补充处理如下： %d - %d", msg_id % 256, msg_id / 256 ) )
			LuaDirector.get_instance():msg_handler(msg)
		end
end
function LuaDirector:msg_handler(msg)
	if NO_GETMSG then return end
	local msg_id = msg:get_msg_id()

	if self.msg_handler_map[msg_id] ~= nil then
		self.msg_handler_map[msg_id](msg)
        cclog( string.format( "[server msg]： %d - %d", msg_id % 256, msg_id / 256 ) )
	else
        print( string.format( "error:没有注册或成功注册如下消息： %d - %d", msg_id % 256, msg_id / 256 ) )
	end
end

function LuaDirector:handler_MSG_CALLBACK_SHOW_MSG(msg)
	local content = msg:get_the_data()
	local c = GameInt_pb.IntData()
	c:ParseFromString(content)
	print("error from server:"..c.data)
end

function LuaDirector.get_instance()
	if(LuaDirector.instance == nil) then
		LuaDirector.instance = LuaDirector.new()
	end
	return LuaDirector.instance
end





----------发送消息------------
function sendMessage(msgname_id,msg)
  local msg = about_login_pb.stUserPreLogin()
  msg.dwCheckCode = 1434993715
  msg.fclientver = 0
  send_msg( msgname_id ,msg)
end

---------接收消息----------
function getMessage(msgid,callback)
  --cclog("从服务器收到消息")
  LuaDirector.get_instance():register_lua_msg(msg_id,callback)
end



function CallbackMsg(m,s,fun)
    if LuaDirector.get_instance():has_registerd(make_cmd(m,s)) == false then
      LuaDirector.get_instance():register_lua_msg(make_cmd(m,s),fun)
    else
     LuaDirector.get_instance():unregister_msg((make_cmd(m,s)))
     LuaDirector.get_instance():register_lua_msg(make_cmd(m,s),fun)
    end 
end
