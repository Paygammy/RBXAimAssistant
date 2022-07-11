local screengui = game:GetObjects('rbxassetid://10028334985')[1]:Clone()
local mainframe = screengui:WaitForChild('MainFrame')
local fovcircle = screengui:WaitForChild('fovCircle')
local maincontent = mainframe:WaitForChild('Content')

-- variables (ui will not uncheck so just a visual bug)
local aimbot = true
local esp = true
local ffa = true
local fov = 4
local sens = .2
local maxcastdist = 500

local target, loadcharacter
local characters = {}
local v2 = Vector2.new
local getregistry = getreg or debug.registry
local getupvalues = getupvalues or debug.getupvalues
local islocalclosure = isourclosure or isexecutorclosure or is_synapse_function

local function getvariablefromregistry(parameters)
	local variable
	for _, f in pairs(getregistry()) do
		if typeof(f) == "function" and not islocalclosure(f) then
			for _, t in pairs(getupvalues(f)) do
				if type(t) == "table" then
					local c = 0
					for _, v in pairs(parameters) do
						if rawget(t, v) then
							c += 1
						end
					end
					if c == #parameters then
						variable = t
					end
				end
			end
		end
	end
	return variable
end

local placeid = game["PlaceId"]
local phantomforces, ragdollgrounds, town
local consoleprint = consoleprint or rconsoleprint
if table.find({299659045, 292439477, 3568020459}, placeid) then
	if isconsoleopen and not isconsoleopen() then
		consoletoggle()
		consoleprint'\n[aim assistant]: loading phantom forces'
	end
	phantomforces = {
		network = getvariablefromregistry {'add', 'send', 'fetch'},
		camera = getvariablefromregistry {'currentcamera', 'setfirstpersoncam', 'setspectate'},
		replication = getvariablefromregistry {'getbodyparts'},
		hud = getvariablefromregistry {'getplayerpos', 'isplayeralive'},
		characters = {},
	}
	if isconsoleopen and not isconsoleopen() then
		consoletoggle()
		consoleprint'\n[aim assistant]: got framework (closing in 5 seconds)'
	end
	task.spawn(function()
		task.wait(5)
		if isconsoleopen and isconsoleopen() then
			return consoletoggle()
		end
	end)
	phantomforces.characters = debug.getupvalue(phantomforces.replication.getbodyparts, 1)
elseif table.find({3161739008}, placeid) then
	ragdollgrounds = true
elseif table.find({4991214437}, placeid) then
	town = true
end

local aimbotcontrol = maincontent:WaitForChild('AimbotController')
local espcontrol = maincontent:WaitForChild('ESPController')
local ffacontrol = maincontent:WaitForChild('FFAController')
local fovcontrol = maincontent:WaitForChild('FOVController')
local senscontrol = maincontent:WaitForChild('SensitivityController')

local ffc = game.FindFirstChild
local ffc2 = game.FindFirstChildWhichIsA
local camera = {}
local utility = {}
local rbxclass = game.IsA
local rbxservice = game.GetService
local rbxdescendant = game.IsDescendantOf

local players = rbxservice(game, 'Players')
local run = rbxservice(game, 'RunService')
local uis = rbxservice(game, 'UserInputService')
local tweening = rbxservice(game, 'TweenService')
local startergui = rbxservice(game, 'StarterGui')

startergui:SetCore('SendNotification', {Title = 'Thank You', Text = 'Created by shawnjbragdon', Duration = 10, Button1 = 'OK'})
startergui:SetCore('SendNotification', {Title = 'Early Build', Text = 'Expect some bugs', Duration = 10, Button1 = 'OK'})

local localplayer = players.LocalPlayer
local playermouse = localplayer:GetMouse()

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

do
	local currentcamera = workspace.CurrentCamera
	camera.wtsp = currentcamera.WorldToScreenPoint
	camera.currentcamera = currentcamera
	local function restorecamera()
		while not typeof(currentcamera) == 'Instance' and not currentcamera:IsA('Camera') do
			currentcamera = workspace.CurrentCamera
			camera.currentcamera = currentcamera
			run.Heartbeat:Wait()
		end
		return currentcamera
	end
	camera.restorestore = restorecamera
	local function cameraready()
		return typeof(currentcamera) == 'Instance' and currentcamera:IsA('Camera')
	end
	camera.cameraready = cameraready 
	workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(restorecamera)
	function camera.onprerender(time, deltaTime)
		if cameraready() then

		end
	end
	run.Stepped:Connect(camera.onprerender)
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
				local humanoid = character and ffc2(character, "Humanoid")
				if phantomforces and lt ~= team then
					if phantomforces.hud:getplayerhealth(player) > 0 then
						table.insert(l, character)
					end
				elseif humanoid and humanoid.Health > 0 then
					if ragdollgrounds then
						local friendly = select(2, pcall(function() return localplayer.Group.Value ~= player.Group.Value end))
						if friendly == true then
							table.insert(l, character)
						end
					elseif lt ~= team then
						table.insert(l, character)
					end
				end
			end
		end
	end
	return l
end

local raycast, ray = workspace.FindPartOnRayWithIgnoreList, Ray.new
local colorset = {
	tlockedcol = Color3.fromRGB(0, 172, 255),
	tinviewcol = Color3.fromRGB(38, 255, 99),
	toutviewcol = Color3.fromRGB(255, 37, 40)
}
local white = Color3.new(1, 1, 1)

local function getnearest()
	local closest_character, closest_screenpoint
	local distance_fovbased = 2048
	local position_camera = camera.currentcamera.CFrame.Position
	for _, character in pairs(getenemychars()) do
		local humanoid = ffc2(character, 'Humanoid')
		if phantomforces or typeof(humanoid) ~= 'Instance' or (rbxclass(humanoid, 'Humanoid') and humanoid.Health > 0) then
			local tcol = colorset.toutviewcol
			local lock = false
			if character == target then
				tcol = colorset.tlockedcol
				lock = true
			end
			local head = ffc(character, 'Head')
			if typeof(head) == 'Instance' and rbxclass(head, 'BasePart') then
				local fov_position, on_screen = camera.wtsp(camera.currentcamera, head.Position)
				local fov_distance = (v2(playermouse.X, playermouse.Y) - v2(fov_position.X, fov_position.Y)).Magnitude
				if on_screen and fov_distance <= camera.currentcamera.ViewportSize.X / (90 / fov) and fov_distance < distance_fovbased then
					local hit = raycast(workspace, ray(position_camera, (head.Position - position_camera).Unit * 2048), {camera.currentcamera, localplayer.Character})
					if typeof(hit) == 'Instance' and rbxdescendant(hit, character) then
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

local mousebutton1down = false
local mousebutton2down = false

local mousebutton1 = Enum.UserInputType.MouseButton1
local mousebutton2 = Enum.UserInputType.MouseButton2
local inputbegan = Enum.UserInputState.Begin
local inputended = Enum.UserInputState.End

uis.InputBegan:Connect(function(io, gpe)
	if typeof(uis:GetFocusedTextBox()) == 'Instance' then
		return
	end
	if io.UserInputType == mousebutton1 then
		mousebutton1down = true
		print'mousebutton1down'
	elseif io.UserInputType == mousebutton2 then
		mousebutton2down = true
		print'mousebutton2down'
	end
end)

uis.InputEnded:Connect(function(io, gpe)
	if io.UserInputType == mousebutton1 and mousebutton1down then
		mousebutton1down = false
		print'mousebutton1up'
	elseif io.UserInputType == mousebutton2 and mousebutton2down then
		mousebutton2down = false
		print'mousebutton2up'
	end
end)

if syn then
	syn.protect_gui(screengui)
end
screengui.Parent = rbxservice(game, 'CoreGui')

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
				if typeof(character) ~= 'Instance' or not rbxdescendant(character, workspace) then
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
		local vpsize = camera.currentcamera.ViewportSize
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
							if typeof(h) == 'Instance' and rbxclass(h, 'Highlight') then
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
