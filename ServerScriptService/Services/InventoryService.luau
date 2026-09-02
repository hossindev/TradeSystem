-- handels the Inventory logic
-- Initialize all the variables
local InventoryService = {}
local dataStoreService = game:GetService("DataStoreService")
local inventoryDataStore = dataStoreService:GetDataStore("InventoryDataStore_v1") -- DataStore for inventory data even on server restart (_v1 is the version)

local inventories = {} -- In-memory cache of inventories

-- Helper function to create a new inventory
local function newInventory()
	return { items = {} }
end

-- Load inventory from DataStore or create a new one
function InventoryService.loadInventory(player)
	if inventories[player.UserId] then -- if the inventory is already in the memory then return it
		return inventories[player.UserId]
	end
	-- Load from DataStore
	local success, data = pcall(function()
		return inventoryDataStore:GetAsync(player.UserId)
	end)
	if success and data then
		inventories[player.UserId] = data
		return data
	-- if there is no data in the DataStore then create a new inventory	
	elseif success  and data == nil then
		
		local freshInventory = newInventory()
		local success, err = pcall(function()
			inventoryDataStore:SetAsync(player.UserId, freshInventory)
		end)
		inventories[player.UserId] = freshInventory
		return freshInventory
		
	else
		return nil
	end
end


-- Save inventory to DataStore
function InventoryService.saveInventory(player)
	-- gets the inventory from the memory cache
	local inventory = inventories[player.UserId] or newInventory()
	
	local success, err = pcall(function()
		inventoryDataStore:UpdateAsync(player.UserId, function(oldValue)
			return inventory
		end)
	end)
	if not success then
		warn("Failed to save inventory for player " .. player.Name .. ": " .. err)
	end
	
end


-- Delete inventory from memory cache to save memory
function InventoryService.deleteInMemoryInventory(player)
	inventories[player.UserId] = nil
end

-- Get inventory from memory cache or load from DataStore
function InventoryService.getInventory(player)
	return inventories[player.UserId] or InventoryService.loadInventory(player)
end


-- Add  items from inventory
function InventoryService.addItem(player, item)
	local inventory = inventories[player.UserId] or InventoryService.loadInventory(player)
	inventory.items[item] = (inventory.items[item] or 0) + 1 -- adds the item to the inventory
	return inventory -- returns the inventory so we dont have to call getInventory again
end

-- Remove items from inventory
function InventoryService.removeItem(player, item)
	local inventory = inventories[player.UserId] or InventoryService.loadInventory(player)
	if inventory.items[item] then
		inventory.items[item] = inventory.items[item] - 1
		if inventory.items[item] <= 0 then
			inventory.items[item] = nil
		end
	end
	return inventory 
end


return InventoryService
