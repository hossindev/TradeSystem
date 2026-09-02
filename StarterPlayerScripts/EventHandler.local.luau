-- this handler connects the server to the client with the remotes
-- first initialize all variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("TradeService")
local SentRequestEvent = Remotes:WaitForChild("SentRequestEvent")
local AcceptRequestEvent = Remotes:WaitForChild("AcceptRequestEvent")
local DeclineRequestEvent = Remotes:WaitForChild("DeclineRequestEvent")
local ItemAddedEvent = Remotes:WaitForChild("ItemAddedEvent")
local players = game:GetService("Players")
local player = game.Players.LocalPlayer
local gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("SentRequest")
local frame = gui:WaitForChild("Request")
local label = frame.ImageLabel.TextLabel
local playerGui = player.PlayerGui
local items = ReplicatedStorage:WaitForChild("Items")
local slot = ReplicatedStorage:WaitForChild("Ui"):WaitForChild("ItemBackground")
local AcceptTradeEvent = Remotes:WaitForChild("AcceptTradeEvent")
local ValidateTradeEvent = Remotes:WaitForChild("ValidateTradeEvent")
local TradeEndEvent = Remotes:WaitForChild("TradeEndEvent")
local CountDownEvent = Remotes:WaitForChild("CountDownEvent")
local trading
local tradingName

-- we need to find the trading gui because it is not always there and thats why we used the hash to start
local function findTradingGui()
	for _, v in ipairs(playerGui:GetChildren()) do
		if v:IsA("ScreenGui") and v.Name:sub(1, 1) == "#" then -- we check if the gui starts with a # because we know that is the trading gui
			trading = v:FindFirstChild("Trading")
			tradingName = v.Name -- we save the name of the gui in a variable (this is the tradingId)
			break
		end
	end
end

local tradingGui = ReplicatedStorage:WaitForChild("Ui"):WaitForChild("TradingUi")

-- this function is used to build the rich text for the request gui
local function buildTradeRequestText(playerName)
	return string.format(
		'<font color="#FFC94A"><b>@%s</b></font> <font color="#FFFFFF"><b>Sent you a</b></font>\n<font color="#FFFFFF"><b>Trade Request!</b></font>', 
		playerName
	)
end

-- this function receives the request of a player and displays it to the player to accept or decline it
SentRequestEvent.OnClientEvent:Connect(function(player,tradeId)
	
	frame.Name = player.Name
	frame:SetAttribute("tradeId",tradeId) -- we set the name of the frame to the player name and the tradeId as an attribute so we can access it on accept or decline
	label.Text = buildTradeRequestText(player.Name)
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	frame.Visible = true
	
end)

-- this function is used to accept a request and create the trading gui
AcceptRequestEvent.OnClientEvent:Connect(function(otherPlayer, tradeId)
	-- we destroy all other trading guis
	for _, v in ipairs(player.PlayerGui:GetChildren()) do
		if v:IsA("ScreenGui") and v.Name:sub(1, 1) == "#" then
			v:Destroy()
		end
	end
	-- we clone the trading gui into the playerGui and set the names of the players
	local clone1 = tradingGui:Clone()
	clone1.Name = tradeId
	clone1.Trading.ImageLabel.You.ImageLabel.TextLabel.Text = player.Name .. " (You)"
	clone1.Trading.ImageLabel.Other.ImageLabel.TextLabel.Text = otherPlayer.Name
	clone1.Parent = player.PlayerGui
	clone1.Enabled = true
end)


-- this function is used to repopulate the items of the trading gui
ItemAddedEvent.OnClientEvent:Connect(function(trade)
	findTradingGui()
	-- we check if the trading gui exists
	if trading then
		trading.Visible = true
		-- we get the frames of the trading gui
		local youFrame = trading.ImageLabel.You.itemFrame
		local otherFrame = trading.ImageLabel.Other.itemFrame
		-- we clear the items in the itemframe so they dont duplicate of the trading gui
		for _, child in ipairs(youFrame:GetChildren()) do
			if child:IsA("GuiObject") and not child:IsA("UIListLayout") and child.Name  ~= "AddItem" then
				child:Destroy()
			end
		end
		
		for _, child in ipairs(otherFrame:GetChildren()) do
			if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		
		-- we get the items of the trading and populate the itemframes
		local function populate(itemList, parentFrame)
			for i, v in pairs(itemList) do
				local item = items:FindFirstChild(v)
				if item then
					local clone = item:Clone()
					local slotclone = slot:Clone()
					clone.Name = v
					slotclone.Name = v
					clone.Parent = slotclone
					slotclone.TextLabel.Text = v
					slotclone.Parent = parentFrame
				end
			end
		end
		
		-- we check if the player is player1 or player2 and populate the itemframes accordingly
		if trade["player1"] == player then
			populate(trade["ItemsPlayer1"], youFrame)
			populate(trade["ItemsPlayer2"], otherFrame)
		elseif trade["player2"] == player then
			populate(trade["ItemsPlayer2"], youFrame)
			populate(trade["ItemsPlayer1"], otherFrame)
		end
	end
end)

-- this function is used to show that the other player is ready or not
AcceptTradeEvent.OnClientEvent:Connect(function(action,tradeId)
	findTradingGui()
	if trading then 
		local otherFrame = trading.ImageLabel.Other
		
		otherFrame.Ready.Visible = action -- we set the visibility of the ready image to the action parameter which is true if ready or false on cancel
		
		
	end
end)


-- this function is used to show the countdown of the trade
CountDownEvent.OnClientEvent:Connect(function(Time)
	findTradingGui()
	local youFrame = trading.ImageLabel.You
	local otherFrame = trading.ImageLabel.Other
	local readyYou = youFrame.Ready
	local readyOther = otherFrame.Ready
	local readyYouText = youFrame.Ready.TextLabel
	local readyOtherText = otherFrame.Ready.TextLabel
	if Time == "Executing Trade" then
		readyYouText.Text = Time
		readyOtherText.Text = Time
		task.wait(0.5) -- we wait 0.5 seconds before destroying the trading gui while the trade is executed on the server
		trading:Destroy()
		return
	end 
	readyYouText.Text = Time .. "s"
	readyOtherText.Text = Time .. "s"
end)