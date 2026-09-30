-- RYVORA LIBRARY SCRIPTS
-- This script gives you easy access to your local Player functions in a safe manner.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = {
	moveToFinished = { _callbacks = {}, _i = 0 },
	teleport = {
		_activeTween = nil,
	},
	SimpleBody = {},
}

--=====================================================================
-- CORE GETTERS
--=====================================================================

function LocalPlayer.getPlayer()
	return Players.LocalPlayer or nil
end

function LocalPlayer.getCharacter()
	local plr = LocalPlayer.getPlayer()
	if plr then
		return plr.Character or nil
	end
	return nil
end

function LocalPlayer.getHumanoid()
	local chr = LocalPlayer.getCharacter()
	if chr then
		return chr:FindFirstChildWhichIsA("Humanoid") or nil
	end
	return nil
end

function LocalPlayer.getCharacterRoot()
	local chr = LocalPlayer.getCharacter()
	if not chr then return end
	return chr:FindFirstChild("HumanoidRootPart") or chr.PrimaryPart or nil
end

--=====================================================================
-- BASIC ACTIONS
--=====================================================================

function LocalPlayer.jump()
	local hum = LocalPlayer.getHumanoid()
	if not hum then return end
	hum.Jump = true
end

--=====================================================================
-- MOVETO
--=====================================================================

function callMoveToFinished(successValue)
	for _, v in pairs(LocalPlayer.moveToFinished._callbacks) do
		if v ~= nil then
			pcall(v, successValue)
		end
	end
end

function LocalPlayer.moveTo(position, forced)
	if not position then
		error("You must specify a position to move to!")
		return
	end

	local forced = forced or false
	local hum = LocalPlayer.getHumanoid()
	if not hum then return end
	hum:MoveTo(position)

	local finished = hum.MoveToFinished:Connect(function(success)
		if success then
			callMoveToFinished(true)
			finished:Disconnect()
			return
		end
		if forced then
			hum:MoveTo(position)
			return
		end
		callMoveToFinished(false)
		finished:Disconnect()
	end)
end

function LocalPlayer.moveToFinished.Connect(callback)
	LocalPlayer.moveToFinished._callbacks[LocalPlayer.moveToFinished._i] = callback
	LocalPlayer.moveToFinished._i += 1
	return LocalPlayer.moveToFinished._i - 1
end

function LocalPlayer.moveToFinished.Disconnect(i)
	LocalPlayer.moveToFinished._callbacks[i] = nil
end

--=====================================================================
-- TELEPORT
--=====================================================================

function LocalPlayer.teleport.instant(position)
	local root = LocalPlayer.getCharacterRoot()
	if not root then return end
	local cf = CFrame.new(position) * CFrame.fromOrientation(table.unpack(root.CFrame:ToOrientation()))
	root.CFrame = cf
end

function LocalPlayer.teleport.stopTween()
	if LocalPlayer.teleport._activeTween then
		LocalPlayer.teleport._activeTween.running = false
		LocalPlayer.teleport._activeTween = nil
	end
end

function LocalPlayer.teleport.isTweening()
	return LocalPlayer.teleport._activeTween ~= nil
end

-- duration: seconds
-- yields until finished (or cancelled)
function LocalPlayer.teleport.tween(position, duration)
	if not position then
		error("You must specify a position to tween to!")
		return false
	end
	duration = duration or 0.2

	-- Cancel any existing tween before starting a new one
	LocalPlayer.teleport.stopTween()

	local root = LocalPlayer.getCharacterRoot()
	if not root then return false end

	local hum = LocalPlayer.getHumanoid()

	local startCF = root.CFrame
	local targetCF = CFrame.new(position) * CFrame.fromOrientation(table.unpack(startCF:ToOrientation()))
	local startTime = os.clock()
	local wasAnchored = root.Anchored

	-- Physics will fight a CFrame tween; anchor during the tween.
	root.Anchored = true

	local state = { running = true }
	LocalPlayer.teleport._activeTween = state

	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Physics)
	end

	while state.running do
		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / duration, 0, 1)

		-- Re-fetch root each frame: respawn/despawn mid-tween must abort cleanly
		local currentRoot = LocalPlayer.getCharacterRoot()
		if not currentRoot or currentRoot ~= root then
			break
		end

		root.CFrame = startCF:Lerp(targetCF, alpha)

		if alpha >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end

	-- Restore anchor state only if we still own this root
	local finalRoot = LocalPlayer.getCharacterRoot()
	if finalRoot == root then
		root.Anchored = wasAnchored
		if hum and hum.Parent then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	state.running = false
	if LocalPlayer.teleport._activeTween == state then
		LocalPlayer.teleport._activeTween = nil
	end

	return true
end

--=====================================================================
-- CHAT
--=====================================================================

function LocalPlayer.sendGlobalChat(message)
	if type(message) ~= "string" or message == "" then return end
	local channels = TextChatService:FindFirstChild("TextChannels")
	if not channels then return end
	local general = channels:FindFirstChild("RBXGeneral")
	if not general then return end
	general:SendAsync(message)
end

--=====================================================================
-- SIMPLE BODY
-- Returns R6-named parts regardless of whether the character is R6 or R15.
-- nil when the character is missing, dead, or a custom rig.
--=====================================================================

local _bodyCache = { character = nil, parts = nil }

local function resolveBodyParts()
	local chr = LocalPlayer.getCharacter()
	if not chr then return nil end

	if _bodyCache.character == chr and _bodyCache.parts then
		return _bodyCache.parts
	end

	local hum = chr:FindFirstChildWhichIsA("Humanoid")
	if not hum then return nil end

	local rigType = hum.RigType

	local parts = {}

	if rigType == Enum.HumanoidRigType.R6 then
		local names = {
			"Head", "Torso",
			"Left Arm", "Right Arm",
			"Left Leg", "Right Leg",
		}
		for _, n in ipairs(names) do
			local p = chr:FindFirstChild(n)
			if p then parts[n] = p end
		end
		parts.LeftArm = parts["Left Arm"]
		parts.RightArm = parts["Right Arm"]
		parts.LeftLeg = parts["Left Leg"]
		parts.RightLeg = parts["Right Leg"]
	else
		-- R15: map to R6-equivalent "primary" parts.
		local function pick(...)
			for _, n in ipairs({ ... }) do
				local p = chr:FindFirstChild(n)
				if p then return p end
			end
			return nil
		end
		parts.Head = pick("Head")
		parts.Torso = pick("UpperTorso", "LowerTorso", "Torso")
		parts.LeftArm = pick("LeftUpperArm", "LeftLowerArm", "LeftHand")
		parts.RightArm = pick("RightUpperArm", "RightLowerArm", "RightHand")
		parts.LeftLeg = pick("LeftUpperLeg", "LeftLowerLeg", "LeftFoot")
		parts.RightLeg = pick("RightUpperLeg", "RightLowerLeg", "RightFoot")
	end

	_bodyCache.character = chr
	_bodyCache.parts = parts
	return parts
end

setmetatable(LocalPlayer.SimpleBody, {
	__index = function(_, key)
		local parts = resolveBodyParts()
		if not parts then return nil end
		return parts[key]
	end,
})

-- Invalidate cache on respawn
do
	local function bind(plr)
		plr.CharacterAdded:Connect(function()
			_bodyCache.character = nil
			_bodyCache.parts = nil
		end)
	end

	local plr = Players.LocalPlayer
	if plr then
		bind(plr)
	end
	Players.PlayerAdded:Connect(function(p)
		if p == Players.LocalPlayer then
			bind(p)
		end
	end)
end

return LocalPlayer
