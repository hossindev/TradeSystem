-- handles the trading logic between players

-- Initialize all the variables
local TradingService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryService = require(script.Parent.InventoryService)
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("TradeService")
local SentRequestEvent = Remotes:WaitForChild("SentRequestEvent")
local AcceptRequestEvent = Remotes:WaitForChild("AcceptRequestEvent")
local DeclineRequestEvent = Remotes:WaitForChild("DeclineRequestEvent")
local ItemAddedEvent = Remotes:WaitForChild("ItemAddedEvent")
local ValidateTradeEvent = Remotes:WaitForChild("ValidateTradeEvent")
local TradeEndEvent = Remotes:WaitForChild("TradeEndEvent")
local AcceptTradeEvent = Remotes:WaitForChild("AcceptTradeEvent")
local CountDownEvent = Remotes:WaitForChild("CountDownEvent")
local trades = {} -- Store active trades 

-- Helper function to generate a unique trade ID to identify each trade
local function shortId(length)
	length = length or 6
	local chars =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local id = "#" -- Start with a hash to make it easier to look up the tradeGui in the UI
	
	
	repeat
		local candidate = ""
		for _ = 1, length do
			local rand = math.random(1, #chars) -- Get a random index
			candidate..= chars:sub(rand, rand) -- Append the random character to the candidate
		end
		id = id .. candidate
	until not trades[id] -- Ensure the ID is unique
	
	return id
end

-- Helper function to count items in a list(the players inventory)
local function countItems(itemList)
	local counts = {}
	for _, item in pairs(itemList) do
		counts[item] = (counts[item] or 0) + 1
	end
	return counts
end

-- Helper function to validate an offer against a player's inventory so exploiting gets prevented
local function validateOffer(itemList, inventory)
	local counts = countItems(itemList)
	for item, offeredAmount in pairs(counts) do
		local ownedAmount = inventory.items[item] or 0
		if offeredAmount > ownedAmount then
			return false, item
		end
	end
	return true
end

-- Helper function to create a trade table that will be used to get data
function TradingService.createTrade(player1, player2)
	local tradeId = shortId()
	trades[tradeId] = { -- we create a trade table with the unique trade id
		tradeId = tradeId,
		player1 = player1,
		player2 = player2,
		ItemsPlayer1 = {},
		ItemsPlayer2 = {},
		Status = "Pending",
		StatusPlayer1 = "", 
		StatusPlayer2 = ""
	}
	return tradeId
end

-- send a trade request to another player
function TradingService.sentRequest(player1, player2, tradeId)
	
	SentRequestEvent:FireClient(player2,player1,tradeId)
end


-- accept a trade request and start the trade
function TradingService.acceptRequest(action,tradeId,player1, player2)

	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	if action  then -- the action is true if the player accepts to start the trade and false if the player declines to start the trade 
		trade.Status = "Started"
		player1:SetAttribute("trading",true) -- to identify if the player is trading this will be used in the ui to switch between the trade mode and normal mode of the inventory
		player2:SetAttribute("trading",true)
		-- we fire the event to the player to start the trade and open the ui
		AcceptRequestEvent:FireClient(player1,player2,tradeId) 
		AcceptRequestEvent:FireClient(player2,player1,tradeId)
	else 
		trade.Status = "canceled"
		-- we fire the event to the player which sent the request to inform them
		DeclineRequestEvent:FireClient(player1)
	end
end

-- add an item to the trade and return the trade to the client to update the ui
local function updateTrade(action, tradeId, player1, player2)
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	if action == "item" then
		ItemAddedEvent:FireClient(player1,trade)
		ItemAddedEvent:FireClient(player2,trade)
	end
	
end

-- add an item to the trade and return the trade to the client to update the ui
function TradingService.addItem(tradeId,player,item)
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	local player1 = trade.player1
	local player2 = trade.player2
	if player == player1   then
		table.insert(trade.ItemsPlayer1, item)
	elseif player == player2 then
		table.insert(trade.ItemsPlayer2, item)
	else 
		return false, "Invalid player"
	end
	updateTrade("item",tradeId,player1,player2)
end

-- remove an item from the trade and return the trade to the client to update the ui
function TradingService.removeItem(tradeId,player,item)
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	local player1 = trade.player1
	local player2 = trade.player2
	-- we loop through the items to find the item to remove
	if player == player1   then
		for i,v in pairs(trade.ItemsPlayer1) do 
			if v == item then
				table.remove(trade.ItemsPlayer1,i)
				updateTrade("item",tradeId,player1,player2)
			end
		end
	elseif player == player2 then
		for i,v in pairs(trade.ItemsPlayer2) do
			if v == item then
				table.remove(trade.ItemsPlayer2,i)
				updateTrade("item",tradeId,player1,player2)
			end
		end
		
	else 
		return false, "Invalid player"
	end
	
end

-- execute the trade and swap the items between the players
local function executeTrade(tradeId,player1,player2)
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	-- we check if the players accepted the trade 
	if not (trade.StatusPlayer1 == "Accepted" and trade.StatusPlayer2 == "Accepted") then
		return false, "Trade not validated"
	end
	
	if not (player1 == trade.player1 and player2 == trade.player2) then
		return false, "Invalid players"
	end
	-- we get the inventories of the players to validate the trade
	local itemsPlayer1 = trade.ItemsPlayer1
	local itemsPlayer2 = trade.ItemsPlayer2
	local player1Inventory = InventoryService.getInventory(player1)
	local player2Inventory = InventoryService.getInventory(player2)

	-- we validate the items offered by each player to make sure they have the (or enough) items
	local valid1, badItem1 = validateOffer(itemsPlayer1, player1Inventory)
	if not valid1 then
		return false, "Player1 does not have enough of: " .. badItem1
	end

	local valid2, badItem2 = validateOffer(itemsPlayer2, player2Inventory)
	if not valid2 then
		return false, "Player2 does not have enough of: " .. badItem2
	end
	
	-- execute the swap in a single pass per player to avoid race conditions 
	for _, item in pairs(itemsPlayer1) do
		InventoryService.removeItem(player1, item)
		InventoryService.addItem(player2, item)
	end
	for _, item in pairs(itemsPlayer2) do
		InventoryService.removeItem(player2, item)
		InventoryService.addItem(player1, item)
	end
	-- we save the inventories and remove the trade from memory
	InventoryService.saveInventory(player1)
	InventoryService.saveInventory(player2)
	trades[tradeId] = nil
	-- we fire the events to the clients to update their ui
	player1:SetAttribute("trading",false)
	player2:SetAttribute("trading",false)
	TradeEndEvent:FireClient(player1)
	TradeEndEvent:FireClient(player2)
end

-- validate the offer by checking if both accepted and if so it starts a countdown to give the players time to cancel 
local function validateTrade(tradeId)
	
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	-- we use this to not allow the trade to be validated multiple times
	if trade.Status == "Validating" then
		return false, "Trade already validating"
	end
	
	local player1, player2 = trade.player1, trade.player2
	trade.Status = "Validating"
	local Time
	-- we lopk for 5 seconds and check if both players accepted the trade each time so players can cancel
	for i=1,10 do
		Time = tostring(5 - (i/2))
		if not trade or trade.StatusPlayer1 ~= "Accepted" or trade.StatusPlayer2 ~= "Accepted" then
			break
		end
		CountDownEvent:FireClient(player1,Time)
		CountDownEvent:FireClient(player2,Time)
		task.wait(0.5)
	end
	-- once the countdown is over we execute the trade
	executeTrade(tradeId,player1,player2)
	-- we fire the events to the clients to update their ui
	local Time = "Executing Trade"
	CountDownEvent:FireClient(player1,Time)
	CountDownEvent:FireClient(player2,Time)	
end

-- if player accepts the trade we set the status to accepted and fire the event to the other player
function TradingService.acceptTrade(tradeId,player)
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	local player1 = trade.player1
	local player2 = trade.player2
	if player == player1 then
		trade.StatusPlayer1 = "Accepted"
		AcceptTradeEvent:FireClient(player2,true,tradeId)
	elseif player == player2 then
		trade.StatusPlayer2 = "Accepted"
		AcceptTradeEvent:FireClient(player1,true,tradeId)
	else 
		return false, "Invalid player"
	end
	-- if both players accepted the trade we validate it
	if trade.StatusPlayer1 == "Accepted" and trade.StatusPlayer2 == "Accepted" then
		validateTrade(tradeId)
	end
	
end

--if player tabs out of the trade or declines while validating 
function TradingService.declineTrade(tradeId,player) 
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	local player1 = trade.player1
	local player2 = trade.player2
	if player ~= player1 and player ~= player2 then
		return false, "Invalid player"
	end

	if player == player1 then
		trade.StatusPlayer1 = "Declined"
	else
		trade.StatusPlayer2 = "Declined"
	end
	
	trade.Status = "canceled"
	player1:SetAttribute("trading",false)
	player2:SetAttribute("trading",false)
	trades[tradeId] = nil

	TradeEndEvent:FireClient(player1)
	TradeEndEvent:FireClient(player2)
end

-- if the player cancels the validation we set the status to trading and fire the event to the other player and enter add mode
function TradingService.declineTradeAndEnterAddMode(tradeId,player) 
	local trade = trades[tradeId]
	if not trade then
		return false, "Trade not found"
	end
	local player1 = trade.player1
	local player2 = trade.player2
	if player ~= player1 and player ~= player2 then
		return false, "Invalid player"
	end
	if player == player1 then
		AcceptTradeEvent:FireClient(player2,false,tradeId)
		trade.StatusPlayer1 = "trading"
	else 
		AcceptTradeEvent:FireClient(player1,false,tradeId)
		trade.StatusPlayer2 = "trading"
	end
	
end



return TradingService
 