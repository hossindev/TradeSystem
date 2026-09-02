
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local part = workspace:WaitForChild("ButtonPart") 
local button = part.SurfaceGui.Frame.TextButton


local originalSize = button.Size

local hoverTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pressTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local AddItemEvent = game.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("InventoryService"):WaitForChild("AddItemEvent")


local function scaleTo(multiplier, tweenInfo)
	local goalSize = UDim2.new(
		originalSize.X.Scale * multiplier,
		originalSize.X.Offset * multiplier,
		originalSize.Y.Scale * multiplier,
		originalSize.Y.Offset * multiplier
	)
	local tween = TweenService:Create(button, tweenInfo, {Size = goalSize})
	tween:Play()
end


button.MouseEnter:Connect(function()
	scaleTo(1.05, hoverTweenInfo)
end)


button.MouseLeave:Connect(function()
	scaleTo(1, hoverTweenInfo)
end)


button.MouseButton1Down:Connect(function()
	scaleTo(0.95, pressTweenInfo) 
end)


button.MouseButton1Up:Connect(function()
	scaleTo(1.05, pressTweenInfo) 
end)


button.MouseButton1Click:Connect(function()
	
	AddItemEvent:FireServer("Tung Tung Tung Sahur")
end)

