local isexecutorclosure = isexecutorclosure or is_synapse_function
assert(type(isexecutorclosure) == 'function', "Unsupported exploit.")
local aimbot, esp, ffa, fov, sens, maxcastdist = true, true, true, 4, .2, 500
local screengui = game:GetObjects('rbxassetid://10028334985')[1]:Clone()
local mainframe = screengui:WaitForChild('MainFrame')
local fovcircle = screengui:WaitForChild('fovCircle')
local maincontent = mainframe:WaitForChild('Content')
local aimbotcontrol = maincontent:WaitForChild('AimbotController')
local espcontrol = maincontent:WaitForChild('ESPController')
local ffacontrol = maincontent:WaitForChild('FFAController')
local fovcontrol = maincontent:WaitForChild('FOVController')
local senscontrol = maincontent:WaitForChild('SensitivityController')
local camera = {}
local placeid = game["PlaceId"]
local players = game:GetService('Players')
local run = game:GetService('RunService')
local uis = game:GetService('UserInputService')
local startergui = game:GetService('StarterGui')
local localplayer = players.LocalPlayer
local playermouse = localplayer:GetMouse()
local raycast, ray = workspace.FindPartOnRayWithIgnoreList, Ray.new
local colorset = {
	tlockedcol = Color3.fromRGB(0, 172, 255),
	tinviewcol = Color3.fromRGB(38, 255, 99),
	toutviewcol = Color3.fromRGB(255, 37, 40)
}
local mousebutton1down = false
local mousebutton2down = false
local mousebutton1 = Enum.UserInputType.MouseButton1
local mousebutton2 = Enum.UserInputType.MouseButton2
local luaUtils = {}
local characters = {}
local loadcharacter, target

do
	function luaUtils:Scan(content --[[: {string}]]) --[[:{}?]]
		for _, closure in pairs(debug.getregistry()) do
			if type(closure) == 'function' and not isexecutorclosure(closure) then
				for _, upvalue in pairs(debug.getupvalues(closure)) do
					if type(upvalue) == 'table' then
						local i = 0
						for _, v in pairs(content) do
							if rawget(upvalue, v) then
								i += 1
							end
						end
						if i == #content then
							return upvalue
						end
					end
				end
			end
		end
	end
end

if table.find({299659045, 292439477, 3568020459}, placeid) then
	phantomforces = {
		network = luaUtils:Scan {'add', 'send', 'fetch'},
		camera = luaUtils:Scan {'currentcamera', 'setfirstpersoncam', 'setspectate'},
		replication = luaUtils:Scan {'getbodyparts'},
		hud = luaUtils:Scan {'getplayerpos', 'isplayeralive'},
		characters = {},
	}
	phantomforces.characters = debug.getupvalue(phantomforces.replication.getbodyparts, 1)
end

startergui:SetCore('SendNotification', {Title = 'Thank You', Text = 'Created by Paygammy', Duration = 10, Button1 = 'OK'})
startergui:SetCore('SendNotification', {Title = 'Early Build', Text = 'Expect some bugs', Duration = 10, Button1 = 'OK'})

coroutine.resume(coroutine.create(function(dragging, dragInput, dragStart, startPos)
	local function update(input)
		local delta = input.Position - dragStart
		mainframe.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	mainframe.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainframe.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	mainframe.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	uis.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end))

do
	local textbox = fovcontrol:WaitForChild('TextBox')
	textbox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local n = tonumber(textbox.Text)
			if typeof(n) == 'number' then
				fov = n
			else
				fov = 4
			end
		end
	end)
end

do
	local textbox = senscontrol:WaitForChild('TextBox')
	textbox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local n = tonumber(textbox.Text)
			if typeof(n) == 'number' then
				sens = n
			else
				sens = .2
			end
		end
	end)
end

local function getenemychars()
	local l = {}
	if ffa then
		for _, player in pairs(players:GetPlayers()) do
			if player ~= localplayer then
				local character = player.Character
				if phantomforces then
					local char = phantomforces.characters[player]
					if char and typeof(rawget(char, "head")) == "Instance" then
						character = char.head.Parent
					end
					local a
					for i, v in pairs(characters) do
						if v == character then
							a = true
							break
						end
					end
					if not a then
						loadcharacter(character)
					end
				end
				local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
				if phantomforces then
					if phantomforces.hud:getplayerhealth(player) > 0 then
						table.insert(l, character)
					end
				elseif humanoid and humanoid.Health > 0 then
					table.insert(l, character)
				end
			end
		end
	else
		local lt = localplayer.Team
		for _, player in pairs(players:GetPlayers()) do
			if player ~= localplayer then
				local character
				if phantomforces then
					local char = phantomforces.characters[player]
					if char and typeof(rawget(char, "head")) == "Instance" then
						character = char.head.Parent
					end
					local a
					for i, v in pairs(characters) do
						if v == character then
							a = true
							break
						end
					end
					if not a then
						loadcharacter(character)
					end 
				end
				local team = player.Team
				if not character then
					character = player.Character
				end
				local humanoid = typeof(character) == 'Instance' and character:FindFirstChildWhichIsA("Humanoid")
				if phantomforces and lt ~= team then
					if phantomforces.hud:getplayerhealth(player) > 0 then
						table.insert(l, character)
					end
				end
			end
		end
	end
	return l
end

local function getnearest()
	local closest_character, closest_screenpoint
	local distance_fovbased = 2048
	local position_camera = workspace.CurrentCamera.CFrame.Position
	for _, character in pairs(getenemychars()) do
		local humanoid = character:FindFirstChildWhichIsA('Humanoid')
		if phantomforces or typeof(humanoid) ~= 'Instance' or (humanoid:IsA('Humanoid') and humanoid.Health > 0) then
			local tcol = colorset.toutviewcol
			local lock = false
			if character == target then
				tcol = colorset.tlockedcol
				lock = true
			end
			local head = character:FindFirstChild('Head')
			if typeof(head) == 'Instance' and head:IsA('BasePart') then
				local fov_position, on_screen = workspace.CurrentCamera:WorldToScreenPoint(head.Position)
				local fov_distance = (Vector2.new(playermouse.X, playermouse.Y) - Vector2.new(fov_position.X, fov_position.Y)).Magnitude
				if on_screen and fov_distance <= workspace.CurrentCamera.ViewportSize.X / (90 / fov) and fov_distance < distance_fovbased then
					local hit = raycast(workspace, ray(position_camera, (head.Position - position_camera).Unit * 2048), {workspace.CurrentCamera, localplayer.Character})
					if typeof(hit) == 'Instance' and hit:IsDescendantOf(character) then
						distance_fovbased = fov_distance
						closest_character = character
						closest_screenpoint = fov_position
						if lock == false then
							for h, c in pairs(characters) do
								if c == character then
									tcol = colorset.tinviewcol
									tcol = colorset.tinviewcol
									break
								end
							end
						end
					end
				end
			end
			for h, c in pairs(characters) do
				if c == character then
					h.FillColor = tcol
					h.OutlineColor = tcol
					break
				end
			end
		end
	end
	return closest_character, closest_screenpoint
end

uis.InputBegan:Connect(function(io, gpe)
	if typeof(uis:GetFocusedTextBox()) == 'Instance' then
		return
	end
	if io.UserInputType == mousebutton1 then
		mousebutton1down = true
	elseif io.UserInputType == mousebutton2 then
		mousebutton2down = true
	end
end)

uis.InputEnded:Connect(function(io, gpe)
	if io.UserInputType == mousebutton1 and mousebutton1down then
		mousebutton1down = false
	elseif io.UserInputType == mousebutton2 and mousebutton2down then
		mousebutton2down = false
	end
end)

if type(syn) == 'table' and rawget(syn, 'protect_gui') then
	syn.protect_gui(screengui)
end
local core
if type(gethui) == 'function' then
	core = gethui()
else
	core = game:GetService("CoreGui")
end
screengui.Parent = core

do
	local player = {}
	local function getcharacter(player)
		local character = player.Character
		if phantomforces then
			local char = phantomforces.characters[player]
			if char and typeof(rawget(char, "head")) == "Instance" then
				character = char.head.Parent
			end
		end
		return character
	end
	function loadcharacter(character)
		if typeof(character) == 'Instance' then
			local origchar = character
			for highlight, character in pairs(characters) do
				if typeof(character) ~= 'Instance' or not character:IsDescendantOf(workspace) then
					characters[highlight] = nil
					highlight:Destroy()
				elseif character == origchar then
					return
				end
			end
			local highlight = Instance.new('Highlight')
			highlight.Name = character:GetDebugId()
			highlight.Adornee = character
			highlight.Enabled = (ffa or select(2, pcall(function()
				return players:GetPlayerFromCharacter(character).Team == localplayer.Team
			end)) ~= true) and esp
			highlight.FillColor = colorset.toutviewcol
			highlight.OutlineColor = colorset.toutviewcol
			highlight.Parent = screengui
			characters[highlight] = character
			local player = players:GetPlayerFromCharacter(character)
			if typeof(player) == 'Instance' then
				player:GetPropertyChangedSignal("Team"):Connect(function()
					highlight.Enabled = (ffa or select(2, pcall(function()
						return players:GetPlayerFromCharacter(character).Team == localplayer.Team
					end)) ~= true) and esp
				end)
			end
		end
	end
	local function loadplayer(player)
		local c = getcharacter(player)
		if typeof(c) == 'Instance' then
			loadcharacter(c)
		end
		player.CharacterAdded:Connect(function(c)
			local character = c or getcharacter(player)
			return loadcharacter(character)
		end)
	end
	for _, player in pairs(players:GetPlayers()) do
		if player ~= localplayer then
			loadplayer(player)
		end
	end
	players.PlayerAdded:Connect(loadplayer)
	ffacontrol.ImageButton.MouseButton1Up:Connect(function()
		ffa = not ffa
		if ffa then
			ffacontrol.ImageButton.TextLabel.Text = '✓'
		else
			ffacontrol.ImageButton.TextLabel.Text = ''
		end
		for highlight, character in pairs(characters) do
			highlight.Enabled = (ffa or select(2, pcall(function()
				return players:GetPlayerFromCharacter(character).Team == localplayer.Team
			end)) ~= true) and esp
		end
	end)
	espcontrol.ImageButton.MouseButton1Up:Connect(function()
		esp = not esp
		if esp then
			espcontrol.ImageButton.TextLabel.Text = '✓'
			for highlight, character in pairs(characters) do
				highlight.Enabled = (ffa or select(2, pcall(function()
					return players:GetPlayerFromCharacter(character).Team == localplayer.Team
				end)) ~= true) and esp
			end
		else
			espcontrol.ImageButton.TextLabel.Text = ''
			for highlight in pairs(characters) do
				highlight.Enabled = false
			end
		end
	end)
	aimbotcontrol.ImageButton.MouseButton1Up:Connect(function()
		aimbot = not aimbot
		if aimbot then
			aimbotcontrol.ImageButton.TextLabel.Text = '✓'
		else
			aimbotcontrol.ImageButton.TextLabel.Text = ''
		end
		fovcircle.Visible = aimbot
	end)
	function updatemouse()
		local vpsize = workspace.CurrentCamera.ViewportSize
		local x, y = playermouse.X, playermouse.Y
		fovcircle.Position = UDim2.fromOffset(x, y)
		fovcircle.Size = UDim2.fromOffset((vpsize.X / (90 / fov)) * 2, (vpsize.X / (90 / fov)) * 2)
	end
	playermouse.Move:Connect(updatemouse)
	uis:GetPropertyChangedSignal('MouseBehavior'):Connect(updatemouse)
	local c, s, h
	local lastt = 0
	local fdelt = 0.016666666666666666
	function player.onpostrender(deltaTime)
		local time = tick()
		if aimbot and time > lastt + fdelt or (1 / deltaTime < 60) then
			lastt = time
			c, s = getnearest()
			if c and s and mousebutton2down then
				target = c
				mousemoverel((s.X - playermouse.X) * sens, (s.Y - playermouse.Y) * sens)
				updatemouse()
				if esp then
					for i, v in pairs(characters) do
						if v == c then
							h = i
							if typeof(h) == 'Instance' and h:IsA('Highlight') then
								h.FillColor = colorset.tlockedcol
								h.OutlineColor = colorset.tlockedcol
							end
							break
						end
					end
				end
			else
				target = nil
			end
		else
			getnearest()
		end
	end
	lastt = run.Heartbeat:Wait()
	run.Heartbeat:Connect(player.onpostrender)
end
