local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local WalkspeedManager = require(Modules:WaitForChild("WalkspeedManager"))
local SharedFunctions = require(Modules:WaitForChild("SharedFunctions"))
local Utils = require(Modules:WaitForChild("Utils"))
local Icon = require(Modules:WaitForChild("Icon"))

local MAX_AUTOGRAB_DISTANCE_DETECTION = 15

local DivazEvent = ReplicatedStorage:WaitForChild("Event")

local Player: Player = Players.LocalPlayer
local Backpack: Backpack = Player.Backpack

local PlayerStats: Folder = Player:WaitForChild("Stats", 30)
local Combat: Folder = PlayerStats:WaitForChild("Combat", 25)

local ToolPool = Instance.new("Tool")
local Handle = Instance.new("Part")
Handle.Name = "Handle"
Handle.Size = Vector3.new(1, 1, 1)
Handle.Transparency = 0.75
Handle.Anchored = false
Handle.CanCollide = false
Handle.Parent = ToolPool

local Initialized = false
local LastAutoGrabbed = tick()

--//FreeCam v0.0.5
local function wireFreeCamera()
	local FreeCameraButton = Icon.new()
	FreeCameraButton:setLabel("Free Camera")
	FreeCameraButton:autoDeselect(false)
	FreeCameraButton:oneClick()
	FreeCameraButton.selected:Connect(function()
		_G.ToggleFreeCam()
	end)
end

--//Raygun v0.0.1
local function wireRaygun()
	local RaygunCommand = Instance.new("TextChatCommand")
	RaygunCommand.Parent = TextChatService
	RaygunCommand.PrimaryAlias = "/raygun"
	RaygunCommand.Triggered:Connect(function()
		DivazEvent:FireServer({
			Event = "GetRaygun",
		})
	end)
end

--//NailWeapon v0.0.5
local function wireNailWeapon(Character: Model)
	local NailTool = ToolPool:Clone()
	NailTool.Name = "Nails"
	NailTool.Parent = Character
	NailTool:Activate()

	NailTool.Activated:Connect(function()
		Utils.CreateNotification("nails should WORK!")

		DivazEvent:FireServer({
			Event = "Hit",
			ClientHitbox = SharedFunctions.CreateHitbox(Character, 3.8 + 1),
		})
	end)
end

--//SpeedHack v0.0.5
local function wireSpeedHack(Character: Model)
	local Success, Result = pcall(function()
		WalkspeedManager:SetPlayer(Character)
		WalkspeedManager:AddModifier("Skates", nil, 15)
	end)

	if not Success then
		warn(Result)
		Utils.CreateNotification("speed failed, check console")
		StarterGui:SetCore("DevConsoleVisible", true)
	end
end

local function getNearestPlayer(Character: Model)
	local NearestPlayer
	local NearestDistance = math.huge

	for _, OtherPlayer: Player in pairs(Players:GetPlayers()) do
		if OtherPlayer == Player then
			continue
		end

		local OtherCharacter: Model = OtherPlayer.Character
		if not OtherCharacter then
			continue
		end

		local Distance = (OtherCharacter:GetPivot().Position - Character:GetPivot().Position).Magnitude
		if Distance < NearestDistance and Distance <= MAX_AUTOGRAB_DISTANCE_DETECTION then
			NearestPlayer = OtherPlayer
			NearestDistance = Distance
		end
	end

	return NearestPlayer
end

--//AutoGrab v.0.0.5
local function wireAutoGrab(Character: Model)
	RunService.PreRender:Connect(function()
		if not (Combat:GetAttribute("Energy") >= 100) then
			return
		end

		if tick() - LastAutoGrabbed < 0.25 then
			return
		end
		LastAutoGrabbed = tick()

		if getNearestPlayer(Character) then
			Utils.CreateNotification("found a player")

			DivazEvent:FireServer({
				Event = "Grab",
				ClientHitbox = SharedFunctions.CreateHitbox(Character, 6),
			})
		end
	end)
end

--//Startup
local function init(Character)
	if Initialized then
		return
	end
	Initialized = true

	wireSpeedHack(Character)
	wireNailWeapon(Character)
	wireAutoGrab(Character)

	Utils.CreateNotification("speed initialized")
	Utils.CreateNotification("autograb initialized")
	Utils.CreateNotification("fakenails initialized")
end

local function initOnce()
	wireFreeCamera()
	wireRaygun()
end

Player.CharacterAdded:Connect(init)
Player.CharacterRemoving:Connect(function()
	Initialized = false
end)

task.spawn(function()
	local Character = Player.Character

	if Character then
		init(Character)
	end

	initOnce()
end)
