-- handels the Inventory of the Player
-- Initialize the InventoryService
local Players = game:GetService("Players")
local InventoryService = require(script.Parent.Parent.Services.InventoryService)

-- when a player joins the game his Inventory will be loaded
Players.PlayerAdded:Connect(function(player) 
	InventoryService.loadInventory(player)
end)

-- when a player leaves the game his Inventory will be saved and deleted from the Memory to save Memory
Players.PlayerRemoving:Connect(function(player) 
	InventoryService.saveInventory(player)
	InventoryService.deleteInMemoryInventory(player)
end)