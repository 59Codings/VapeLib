local VapeLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/59Codings/VapeLib/refs/heads/main/VapeLib.lua"))() -- // use require if in studio

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer

local ui = VapeLib:CreateWindow({
	Name = "example",
	Keybind = Enum.KeyCode.RightShift,
	Studio = false -- // only add this / enable this if you are using this in studio, dont enable this in actual games or you might get detected
})

local movement = ui:CreateCategory({
	Name = "Movement",
	Icon = "rbxassetid://14368306745"
})

local char, hum, root

local function refresh()
	char = lp.Character or lp.CharacterAdded:Wait()
	hum = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

refresh()
lp.CharacterAdded:Connect(refresh)

local state = {
	enabled = false,
	speed = 23,
	useWS = false,
	heat = false,
	phase = 1,
	timer = 0
}

local heat = {
	boostSpeed = 40,
	normalSpeed = 18,
	boostTime = 0.6,
	normalTime = 0.6
}

local speedMod = movement:CreateModule({
	Name = "Speed",
	Function = function(v)
		state.enabled = v
		state.phase = 1
		state.timer = 0
	end
})

speedMod:CreateSlider({
	Name = "Speed",
	Min = 1,
	Max = 100,
	Default = 23,
	Function = function(v)
		state.speed = v
	end
})

speedMod:CreateToggle({
	Name = "WalkSpeed",
	Default = false,
	Function = function(v)
		state.useWS = v
	end
})

speedMod:CreateToggle({
	Name = "Heatseeker",
	Default = false,
	Function = function(v)
		state.heat = v
		state.phase = 1
		state.timer = 0
	end
})

speedMod:CreateSlider({
	Name = "HS Boost Speed",
	Min = 1,
	Max = 100,
	Default = 40,
	Function = function(v)
		heat.boostSpeed = v
	end
})

speedMod:CreateSlider({
	Name = "HS Normal Speed",
	Min = 1,
	Max = 100,
	Default = 18,
	Function = function(v)
		heat.normalSpeed = v
	end
})

speedMod:CreateSlider({
	Name = "HS Boost Time",
	Min = 1,
	Max = 20,
	Default = 6,
	Function = function(v)
		heat.boostTime = v / 10
	end
})

speedMod:CreateSlider({
	Name = "HS Normal Time",
	Min = 1,
	Max = 20,
	Default = 6,
	Function = function(v)
		heat.normalTime = v / 10
	end
})

RunService.RenderStepped:Connect(function(dt)
	if not state.enabled or not char then return end

	if state.useWS then
		hum.WalkSpeed = state.speed
		return
	end

	local move = hum.MoveDirection
	if move.Magnitude == 0 then return end

	local spd = state.speed

	if state.heat then
		state.timer += dt

		local duration = (state.phase == 1 and heat.boostTime or heat.normalTime)

		if state.timer >= duration then
			state.timer = 0
			state.phase = (state.phase == 1 and 2 or 1)
		end

		spd = (state.phase == 1 and heat.boostSpeed or heat.normalSpeed)
	end

	root.AssemblyLinearVelocity = Vector3.new(
		move.X * spd,
		root.AssemblyLinearVelocity.Y,
		move.Z * spd
	)
end)

ui:Notify({
	Title = "hi",
	Description = "press right shift to toggle ui",
	Duration = 5
})
