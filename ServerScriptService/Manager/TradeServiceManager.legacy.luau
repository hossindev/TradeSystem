-- handels the connection between the TradeService and the Client
--first initialize all variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradingService = require(script.Parent.Parent.Services.TradingService)
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("TradeService")
local SentRequestEvent = Remotes:WaitForChild("SentRequestEvent")
local AcceptRequestEvent = Remotes:WaitForChild("AcceptRequestEvent")
local DeclineRequestEvent = Remotes:WaitForChild("DeclineRequestEvent")
local ItemAddedEvent = Remotes:WaitForChild("ItemAddedEvent")
local AcceptTradeEvent = Remotes:WaitForChild("AcceptTradeEvent")
local RemoveItemEvent = Remotes:WaitForChild("RemoveItemEvent")
local Players = game:GetService("Players")

-- we use this helper function because the client sends the target player name and not the player object so we havbe to convert it
local function getPlayerFromName(targetPlayerName)
	local targetPlayer = Players:FindFirstChild(targetPlayerName)
	if not targetPlayer then
		warn("Target player not found: " .. tostring(targetPlayerName))
		return
	end
	return targetPlayer
end

-- the event gets fired when the player wants to send a trade request to another player
SentRequestEvent.OnServerEvent:Connect(function(player, targetPlayerName)
	local targetPlayer = getPlayerFromName(targetPlayerName) -- we convert the target player name to the player object
	
	local tradeId = TradingService.createTrade(player, targetPlayer) -- we create a trade and get the trade id
	TradingService.sentRequest(player, targetPlayer,tradeId) -- we send the trade request to the target player via the TradeService
end)


-- the event gets fired when the player accepts a trade request
AcceptRequestEvent.OnServerEvent:Connect(function(player, targetPlayerName,tradeId)
	
	TradingService.acceptRequest(true,tradeId,player,getPlayerFromName(targetPlayerName)) -- we accept the trade request via the TradeService
end)

-- the event gets fired when the player declines a trade request
DeclineRequestEvent.OnServerEvent:Connect(function(player, targetPlayerName,tradeId)
	
	TradingService.acceptRequest(false,tradeId,player,getPlayerFromName(targetPlayerName)) -- we decline the trade request via the TradeService
end)


-- the event gets fired when the player adds an item to the trade
ItemAddedEvent.OnServerEvent:Connect(function(player, tradeId, itemName )
	TradingService.addItem(tradeId,player,itemName) -- we add the item to the trade via the TradeService
end)

-- the event gets fired when the player accepts or declines the trade
AcceptTradeEvent.OnServerEvent:Connect(function(player, tradeId, action)
	if action  then -- the action is true if the player accepts the trade and false if the player declines the trade but still wants to add/remove items
		TradingService.acceptTrade(tradeId,player) -- we accept the trade via the TradeService
	else
		TradingService.declineTradeAndEnterAddMode(tradeId,player) -- we decline the trade and enter add mode via the TradeService
	end
end)


-- the event gets fired when the player removes an item from the trade
RemoveItemEvent.OnServerEvent:Connect(function(player, tradeId, itemName)
	TradingService.removeItem(tradeId,player,itemName) -- we remove the item from the trade via the TradeService
end)
