--!strict

export type RyLogErrorLevel = "Log" | "Warn" | "Error" | "Info"

export type RyLogParams = {
	source: string?,
	color: Color3?,
	level: RyLogErrorLevel?,
	timeout: number?,
}

local TweenService = game:GetService("TweenService")

local levelColors = {
	Log = Color3.fromRGB(0, 255, 0),
	Warn = Color3.fromRGB(255, 255, 0),
	Error = Color3.fromRGB(255, 0, 0),
	Info = Color3.fromRGB(255, 255, 255),
}

local uiRoot = gethui()

if getgenv() and getgenv().RyLog then
	return getgenv().RyLog
end

local RyLog = {}

local function makeLabel(text: string, parent: Instance, color: Color3)
	local label = Instance.new("TextLabel", parent)
	label.Text = text
	label.TextColor3 = color
	label.TextTransparency = 1
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 30)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.FontFace = Font.fromName("Inconsolata", Enum.FontWeight.Regular)
	
	local pad = Instance.new("UIPadding", label)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	
	local stroke = Instance.new("UIStroke", label)
	stroke.Transparency = 1
	
	return label, stroke
end

local Gui = Instance.new("ScreenGui", uiRoot)
Gui.ResetOnSpawn = false
Gui.Name = "RyLog - Root Container"

local function showLabel(text: string, color: Color3, timeout: number)
	local label, stroke = makeLabel(text, Gui, color)
	
	local fadeInInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeOutInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	
	local fadeInTween = TweenService:Create(label, fadeInInfo, { TextTransparency = 0 })
	local strokeFadeIn = TweenService:Create(stroke, fadeInInfo, { Transparency = 0 })
	
	fadeInTween:Play()
	strokeFadeIn:Play()
	
	fadeInTween.Completed:Once(function()
		task.delay(timeout, function()
			local fadeOutTween = TweenService:Create(label, fadeOutInfo, { TextTransparency = 1 })
			local strokeFadeOut = TweenService:Create(stroke, fadeOutInfo, { Transparency = 1 })
			
			fadeOutTween:Play()
			strokeFadeOut:Play()
			
			fadeOutTween.Completed:Once(function()
				label:Destroy()
			end)
		end)
	end)
end

function RyLog.push(text: string, params: RyLogParams?)
	assert(text, "A Text is required!")
	local source = params and params.source or nil
	local timeout = params and params.timeout or 5
	local level = params and params.level or "Log"
	local color = params and params.color or levelColors[level]
	
	local displayText = text
	if source then
		displayText = "[ " .. source .. " ] " .. text
	end
	
	showLabel(displayText, color, timeout)
end




local Layout = Instance.new("UIListLayout", Gui)
Layout.Padding = UDim.new(0, 4)

if getgenv() then
	getgenv().RyLog = RyLog
end
return RyLog
