-- Get The Inventory and add Items to the Invenotry

--Initialize all variables
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("InventoryService")
local GetInventoryEvent = ReplicatedStorage:WaitForChild("GetInventoryEvent")
local AddItemEvent = ReplicatedStorage:WaitForChild("AddItemEvent")
local InventoryService = require(script.Parent.Parent.Services.InventoryService) 



GetInventoryEvent.OnServerEvent:Connect(function(player)
	local inventory = InventoryService.getInventory(player)
	GetInventoryEvent:FireClient(player, inventory) -- Returns the invenotry to the client
end)

AddItemEvent.OnServerEvent:Connect(function(player, item)
	
	local inventory = InventoryService.addItem(player, item)
	
	AddItemEvent:FireClient(player, inventory) -- adds the item to the inventory
end)