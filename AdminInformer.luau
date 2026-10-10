local RyLog = _G.RyLog or loadstring(game:HttpGet("https://raw.githubusercontent.com/Ryvora/FOSS/refs/heads/main/Desync.luau"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Env = if getgenv then getgenv() else _G

local AdminInformer = {}

setmetatable(AdminInformer, {
	__tostring = function(self)
		return "Ryvora Script: RyLog Admin Abuse informer"
	end
})

local Tools = {
	ShowFrozen = false,
	ShowJails = false,
	ShowInvisible = false,
	Logging = false
}

local function generateHighlighter(text, id, parent, yOffset)
	local highlight = nil
	local gui = nil
	local label = nil
	
	if not parent:FindFirstChild("__RV_HIGH__") then
		highlight = Instance.new("Highlight", parent)
		highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.Name = "__RV_HIGH__"..id
	end
	
	if not parent:FindFirstChild("__RV_BILL__") then
		gui = Instance.new("BillboardGui", parent)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 100
		gui.Size = UDim2.new(3, 20, 1.5, 0)
		gui.StudsOffset = Vector3.new(0, yOffset, 0)
		gui.Name = "__RV_BILL__"..id

		label = Instance.new("TextLabel", gui)
		label.Font = Enum.Font.Cartoon
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(255, 255, 255)
		label.TextScaled = true
		label.Text = text

		local pad = Instance.new("UIPadding", label)
		pad.PaddingTop = UDim.new(0,5)
		pad.PaddingLeft = pad.PaddingTop
		pad.PaddingBottom = pad.PaddingLeft
		pad.PaddingRight = pad.PaddingBottom

		local stroke = Instance.new("UIStroke", label)
		stroke.Thickness = 4
		stroke.Color = Color3.fromRGB(0, 0, 0)

		label.Text = text
	end
	
	
	
	return {hl=highlight, gui=gui, label=label}
end

function destroyHighlightFor(v, id)
	local high = v:FindFirstChild("__RV_HIGH__"..id)
	local bill = v:FindFirstChild("__RV_BILL__"..id)
	if high then high:Destroy() end
	if bill then bill:Destroy() end
end

function log(v)
	RyLog.push(v)
end

function AdminInformer.enableLogs()
	Tools.Logging = true
end

function AdminInformer.disableLogs()
	Tools.Logging = false
end

function AdminInformer.showJails()
	Tools.ShowJails = true
end

function AdminInformer.hideJails()
	Tools.HideJails = false
end

function AdminInformer.showFrozen()
	Tools.ShowFrozen = true
end

function AdminInformer.hideFrozen()
	Tools.ShowFrozen = false
end

function AdminInformer.showInvisible()
	Tools.ShowInvisible = true
end

function AdminInformer.hideInvisible()
	Tools.ShowInvisible = false
	for _,v in pairs(Players:GetChildren()) do
		if v.Character.Head.Transparency == 0.5 then
			for i,d in pairs(v.Character:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
					d.Transparency = 0
				end
			end
		end
	end
end

local Watchdog = task.spawn(function()
	while task.wait(1) do
		for _, v in pairs(Players:GetPlayers()) do
			if v.Character then
				local root = (v.Character:FindFirstChild("HumanoidRootPart") or v.Character.PrimaryPart)
				if not root then continue end
				if root then
					if Tools.ShowFrozen and  root.Anchored then
						generateHighlighter("Frozen", "frozen", v.Character, 5)
					else
						destroyHighlightFor(v.Character, "frozen")
					end
				end
				
				
				if v.Character.Head.Transparency ~= 0 and Tools.ShowInvisible then
					for i,d in pairs(v.Character:GetDescendants()) do
						if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
							d.Transparency = 0.5
						end
					end
				end
				
				
				-- UnSpoof Names
				
				if v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.DisplayName ~= "" then
					log("Name Unspoof: " .. v.Character.Humanoid.DisplayName .. " -> " .. v.Name)
					v.Character.Humanoid.DisplayName = ""
				end
				
			end
		end
		
		
		for _,v in pairs(Workspace:GetChildren()) do
			if Tools.ShowJails then
				if v.Name == "JailCell" then
					generateHighlighter("Unknown Jail Owner - HD Admin v2", "jail", v, 5)
				end
				
				if v.Name:sub(#v.Name-7) == "JailCell" then
					generateHighlighter(v.Name, "jail", v, 5)
				end
			else
				destroyHighlightFor(v, "jail")
			end
		end
	end
end)

if getgenv() then
	if getgenv().Ryvora__AdminInformer then return getgenv().Ryvora__AdminInformer end
	getgenv().Ryvora__AdminInformer = AdminInformer
end

return AdminInformer
