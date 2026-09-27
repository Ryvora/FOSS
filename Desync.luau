local Desync = {
	origChar = nil,
	clone = nil,
	destroyingConn = nil,
	desyncHighlight = nil,
	freezer = nil,
	op = nil,
	update = false,
	reanchorTime = nil,
	guiParent = Instance.new("Folder", game:GetService("Lighting")),

	transparencies = {

	},
	
	collisions = {
		
	}
}

Desync.guiParent.Name = "__RV_DESYNC_GUIS_RVV__"

-- Services
local Svc = {
	Players = game:GetService("Players"),
	Workspace = game:GetService("Workspace"),
	Run = game:GetService("RunService")
}
local Player = Svc.Players.LocalPlayer

function Desync.backupGuis() 
	for i,v in pairs(Player.PlayerGui:GetChildren()) do
		v.Parent = Desync.guiParent
	end
end

function Desync.restoreGuis() 
	for i,v in pairs(Desync.guiParent:GetChildren()) do
		v.Parent = Player.PlayerGui
	end
end

function Desync.start(allowCloneRespawn)
	local allowCloneRespawn = allowCloneRespawn or true
	-- Only allow one clone
	if Desync.clone then return end
	
	Desync.backupGuis() 

	local char = Player.Character
	Desync.origChar = char

	local root = Desync.origChar:FindFirstChild("HumanoidRootPart") or Desync.origChar.PrimaryPart
	Desync.op = root.CFrame
	
	Desync.freezer = Svc.Run.Heartbeat:Connect(function(delta)
		if Desync.update then
			if Desync.reanchorTime == nil then
				root.CFrame = Desync.op -- Move
				root.Anchored = false -- Unanchor for refresh
				Desync.reanchorTime = 0.15 -- This is basically a timer to say when to reanchor
			elseif Desync.reanchorTime > 0 then
				Desync.reanchorTime = Desync.reanchorTime - delta
				--print(Desync.reanchorTime)
			else
				--print("done")
				Desync.update = false
				Desync.reanchorTime = nil
				root.Anchored = true
			end
		end
		root:PivotTo(Desync.op)-- = Desync.op -- CFrame Freeze
		if Desync.clone.Parent == nil then
			if allowCloneRespawn then
				local cloneRoot = Desync.clone:FindFirstChild("HumanoidRootPart") or Desync.clone.PrimaryPart
				cloneRoot.CFrame = Desync.op
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
	
	-- Before setting Character, we save the camera, BECAUSE the camera orientation will otherwise be RESET!
	local cam = game.Workspace.CurrentCamera
	local Orient = cam.CFrame
	
	Player.Character = Desync.clone
	
	-- Reset CFrame on change
	local conn
	conn = cam:GetPropertyChangedSignal("CFrame"):Connect(function()
		conn:Disconnect()
		cam.CFrame = Orient
	end)

	
	Desync.clone.Humanoid.Died:Connect(Desync.stop)
	Desync.clone.AncestryChanged:Connect(Desync.stop)

	-- We have to disconnect this otherwise we run into a loop!
	Desync.destroyingConn = Desync.clone.Destroying:Connect(function()
		Desync.stop(true)
	end)

	Desync.setOrigTransparency(0.999)
	
	Desync.restoreGuis() 
end

function Desync.setOrigPosition(posOrCFrame)
	Desync.update = true
	if typeof(posOrCFrame) == "Vector3" then
		Desync.op = CFrame.new(posOrCFrame)
	else
		Desync.op = posOrCFrame
	end
end

-- TODO: Fix this. Idk why it doesnt work
function Desync.moveOrigPosition(vec)
	Desync.update = true
	Desync.op = CFrame.new(Desync.op.Position + vec)	
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

function Desync.stop(goToClone, viaDestroy)
	Desync.resetOrigTransparency()
	
	local goToClone = goToClone or true
	local viaDestroy = viaDestroy or false

	-- Only run if there is a clone
	if not Desync.clone then return end
	
	Desync.backupGuis() 
	
	local origChar = Desync.origChar
	local clone = Desync.clone
	Desync.freezer:Disconnect()
	local oprim = (origChar:FindFirstChild("HumanoidRootPart") or origChar.PrimaryPart)
	oprim.CFrame = (clone:FindFirstChild("HumanoidRootPart") or clone.PrimaryPart).CFrame

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
	
	-- Before setting Character, we save the camera, BECAUSE the camera orientation will otherwise be RESET!
	local cam = game.Workspace.CurrentCamera
	local Orient = cam.CFrame

	Player.Character = Desync.origChar

	-- Reset CFrame on change
	local conn
	conn = cam:GetPropertyChangedSignal("CFrame"):Connect(function()
		conn:Disconnect()
		cam.CFrame = Orient
	end)
	
	local root = Desync.origChar:FindFirstChild("HumanoidRootPart") or Desync.origChar.PrimaryPart
	root.Anchored = false
	root.CanCollide = true

	Desync.desyncHighlight:Destroy()
	
	Desync.restoreGuis() 
end

_G.RyvoraDesync = _G.RyvoraDesync or Desync

return _G.RyvoraDesync
