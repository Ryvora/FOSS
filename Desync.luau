-- LOADSTRING:
-- local Desync = loadstring(game:HttpGet("ryvora.github.io/FOSS/Desync.luau"))()
local Desync = {
	origChar = nil,
	clone = nil,
	destroyingConn = nil,
	desyncHighlight = nil,
	freezer = nil,
		
	transparencies = {
			
	}
}

-- Services
local Svc = {
	Players = game:GetService("Players"),
	Workspace = game:GetService("Workspace"),
	Run = game:GetService("RunService")
}
local Player = Svc.Players.LocalPlayer

function Desync.start(allowCloneRespawn)
	local allowCloneRespawn = allowCloneRespawn or true
	-- Only allow one clone
	if Desync.clone then return end
	
	local char = Player.Character
	Desync.origChar = char
	
	local root = Desync.origChar:FindFirstChild("HumanoidRootPart") or Desync.origChar.PrimaryPart
	local ocf = root.CFrame
	
	Desync.freezer = Svc.Run.Heartbeat:Connect(function()
		root.CFrame = ocf -- CFrame Freeze
		if Desync.clone.Parent == nil then
			if allowCloneRespawn then
				local cloneRoot = Desync.clone:FindFirstChild("HumanoidRootPart") or Desync.clone.PrimaryPart
				cloneRoot.CFrame = ocf
				Desync.clone.Parent = Svc.Workspace
			else
				Desync.stop()
			end
		end	

		-- Died via VOID, can't restart
		if Desync.clone:FindFirstChild("HumanoidRootPart") == nil and Desync.clone.PrimaryPart == nil then
			Desync.stop()
			--Desync.start()
		end
	end)
	
	local humanoid = char.Humanoid

	-- Make Archivable so we can clone
	local origArchive = char.Archivable
	char.Archivable = true

	Desync.clone = char:Clone(true)

	-- Create highlight AFTER we clone!
	local highlight = Instance.new("Highlight", Desync.origChar)
	highlight.OutlineColor = Color3.fromRGB(0, 105, 255)
	highlight.OutlineTransparency = 0.5
	highlight.FillTransparency = 1
	Desync.desyncHighlight = highlight

	-- Same with Anchor and Collision
	root.Anchored = true	
	root.CanCollide = false

	
	char.Archivable = origArchive

	-- Parent to Workspace and rename
	Desync.clone.Parent = Svc.Workspace
	Desync.clone.Name = Desync.clone.Name .. "__RYV__CLONE__DESYNC"

	Svc.Workspace.CurrentCamera.CameraSubject = Desync.clone.Humanoid
	Player.Character = Desync.clone

	Desync.clone.Humanoid.Died:Connect(Desync.stop)
	Desync.clone.AncestryChanged:Connect(Desync.stop)

	-- We have to disconnect this otherwise we run into a loop!
	Desync.destroyingConn = Desync.clone.Destroying:Connect(function()
		Desync.stop(true)
	end)

	Desync.setOrigTransparency(0.999)
end

function Desync.setOrigPosition(posOrCFrame)
	if Desync.origChar == nil then return end

	local root = Desync.origChar:FindFirstChild("HumanoidRootPart") or Desync.origChar.PrimaryPart
	if typeof(posOrCFrame) == "Vector3" then
		root.CFrame = CFrame.new(pos)
	else
		root.CFrame = posOrCFrame
	end
end

function Desync.moveOrigPosition(vec)
	if Desync.origChar == nil then return end

	local root = Desync.origChar:FindFirstChild("HumanoidRootPart") or Desync.origChar.PrimaryPart
	root.CFrame = CFrame.new(root.CFrame + vec)
end

function Desync.setOrigTransparency(value)
	local value = value or 0.5
	
	local char = Desync.origChar
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") and v.Name ~= "HumanoidRootPart" then

			-- Basically do a value backup
			if not Desync.transparencies[v.Name] then
				Desync.transparencies[v.Name] = v.Transparency
			end

			-- Set transparency
			v.Transparency = value
		end
	end
end


function Desync.resetOrigTransparency()
	local char = Desync.origChar
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			if Desync.transparencies[v.Name] then
				v.Transparency = Desync.transparencies[v.Name]
			end
		end
	end
end

function Desync.stop(viaDestroy)
	Desync.resetOrigTransparency()
	local viaDestroy = viaDestroy or false

	-- Only run if there is a clone
	if not Desync.clone then return end

	local origChar = Desync.origChar
	local clone = Desync.clone

	-- Disconnect destroy to not loop forever
	if Desync.destroyingConn then
		Desync.destroyingConn:Disconnect()
		Desync.destroyingConn = nil
	end

	-- Destroy clone
	clone:Destroy()
	Desync.clone = nil

	-- Set back to orig Char
	local origChar = Desync.origChar or Svc.Workspace:FindFirstChild(Player.Name, true) -- Emergency Fallback; try to FIND the original player
	Svc.Workspace.CurrentCamera.CameraSubject = Desync.origChar.Humanoid
	Player.Character = Desync.origChar
	local root = Desync.origChar:FindFirstChild("HumanoidRootPart") or Desync.origChar.PrimaryPart
	root.Anchored = false
	root.CanCollide = true

	Desync.desyncHighlight:Destroy()
	Desync.freezer:Disconnect()
end

_G.RyvoraDesync = _G.RyvoraDesync or Desync

return _G.RyvoraDesync
