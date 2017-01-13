UITools = {}

function UITools.add2Center(ctn, child, index)
	child:setAnchorPoint(0.5, 0.5)
	if index ~= nil then
		ctn:addChild(child, index)
	else
		ctn:addChild(child)
	end
	child:setPosition(ctn:getSize().width / 2, ctn:getSize().height / 2)
end

function UITools.anchor2(board, target, anchorMode, index)
	local boardSize = board:getSize()

	if index ~= nil then
		board:addChild(target, index)
	else
		board:addChild(target)
	end
	if anchorMode == 0 then
		target:setAnchorPoint(0, 0)
		target:setPosition(0, boardSize.height)
	elseif anchorMode == 1 then
		target:setAnchorPoint(0, 1)
		target:setPosition(0, 0)
	elseif anchorMode == 2 then
		target:setAnchorPoint(1,1)
		target:setPosition(boardSize.width, 0)
	elseif anchorMode == 3 then
		target:setAnchorPoint(1, 0)
		target:setPosition(boardSize.width, boardSize.height)
	end
end

function UITools.bindInputNTip(input, tip, tipAsProxy, noInputDesc)
  	local function editListener(eventType)
  	if tipAsProxy == true then
  		if eventType == "began" then 
      		MMR_EditRichText_Plus(tip, " ","左对齐",nil,nil,nil, input:getSize().width)
    	end
    	if eventType == "changed" then
    		if input:getText() == "" then
  				MMR_EditRichText_Plus(tip, " ","左对齐",nil,nil,nil, input:getSize().width)
      		else
        		MMR_EditRichText_Plus(tip, input:getText(),"左对齐",nil,nil,nil, input:getSize().width)
      		end
    	end
    	if eventType == "ended" or eventType == "return" then
      		if input:getText() == "" then	
  				if noInputDesc ~= nil and noInputDesc ~= "" then
  					MMR_EditRichText_Plus(tip, noInputDesc,"左对齐",nil,nil,nil, input:getSize().width)
  				else
  					MMR_EditRichText_Plus(tip, " ","左对齐",nil,nil,nil, input:getSize().width)
  				end
      		else
        		MMR_EditRichText_Plus(tip, input:getText(),"左对齐",nil,nil,nil, input:getSize().width)
      		end
    	end
  	else
    	if eventType == "began" then 
      		tip:setVisible(false)
    	end
    	if eventType == "ended" or eventType == "return" then
      		if input:getText() == "" then
        		tip:setVisible(true)
      		else
        		tip:setVisible(false)
      		end
    	end
	end
  end
  if tipAsProxy == true then
  	setOpacity(input, 0)
  	if noInputDesc ~= nil and noInputDesc ~= "" then
  		MMR_EditRichText_Plus(tip, noInputDesc,"左对齐",nil,nil,nil, input:getSize().width)
  	end
  end
  input:registerScriptEditBoxHandler(editListener)
end

function UITools.hideAllUI(hide)
	local mainUI = G_MainUILayer--:getChildren()
	local subUI = G_UILayer--:getChildren()

	if hide == true then
		mainUI:setPositionX(10000)
		subUI:setPositionX(10000)
	else
		mainUI:setPositionX(0)
		subUI:setPositionX(0)
	end
end

function UITools.createClipedCircle(parent)
 	local clip = cc.ClippingNode:create()
  	local stencil = cc.DrawNode:create()
  	local radio = parent:getSize().width * 0.5
  	local center = cc.p(radio, radio)  --center模板圆的中心点，可用于调整相对于头像图片的偏移

  	stencil:drawSolidCircle(center, radio, math.pi, 50 ,cc.c4f(0, 0, 0, 1)) 
  	clip:setStencil(stencil) 
  	clip:setAnchorPoint(cc.p(0, 0))
  	parent:addChild(clip)

  	return clip
end

function UITools.createClipedRect(parent, w, h)
  	local clip = cc.ClippingNode:create()
  	local stencil = cc.DrawNode:create()
  	local size = parent:getSize()

  	size.width = w or size.width
  	size.height = h or size.height
  	stencil:drawSolidRect(cc.p(0, 0), cc.p(size.width, size.height), cc.c4f(0, 0, 0, 1)) 
  	clip:setStencil(stencil) 
  	clip:setAnchorPoint(cc.p(0, 0))
  	parent:addChild(clip)

  	return clip
end

function UITools.createClipedPort(parent)
	local port = ccui.ImageView:create()
	local clip = UITools.createClipedCircle(parent)

	port:setScaleX(100 / parent:getSize().width)
	port:setScaleY(100 / parent:getSize().height)
	port:setAnchorPoint(cc.p(0, 0))
	clip:addChild(port)

	return port
end

function UITools.createClipedRT(parent, w, h)
	local rt = ccui.Text:create("","Arial",1)
	local clip = UITools.createClipedRect(parent, w, h)

	rt:setAnchorPoint(cc.p(0, 0))
	clip:addChild(rt)

	return rt
end