local gui_logic = {}

-- Получаем зависимости из getgenv().SS
local SS           = getgenv().SS
local gui_elements = SS.gui_elements

local Background     = gui_elements.Background
local TopBar         = gui_elements.TopBar
local LeftPanel      = gui_elements.LeftPanel
local RightPanel     = gui_elements.RightPanel
local CodeBox        = gui_elements.CodeBox
local ScrollingFrame = gui_elements.ScrollingFrame
local LogList        = gui_elements.LogList
local SimpleSpy3     = gui_elements.SimpleSpy3
local CloseButton    = gui_elements.CloseButton
local ToolTip        = gui_elements.ToolTip
local TextLabel      = gui_elements.TextLabel

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local GuiInset         = game:GetService("GuiService"):GetGuiInset()

local closed = false
local mainClosing = false
local sideClosed = true
local sideClosing = false
local maximized = false
local mouseInGui = false

local connections = {}
local remotesFadeIn
local rightFadeIn

local selectedColor = Color3.new(0.321569, 0.333333, 1)
local deselectedColor = Color3.new(0.8, 0.8, 0.8)

local function fadeOut(elements)
    local data = {}
    for _, v in next, elements do
        if typeof(v) == "Instance" and v:IsA("GuiObject") and v.Visible then
            spawn(function()
                data[v] = {
                    BackgroundTransparency = v.BackgroundTransparency
                }
                TweenService:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                if v:IsA("TextBox") or v:IsA("TextButton") or v:IsA("TextLabel") then
                    data[v].TextTransparency = v.TextTransparency
                    TweenService:Create(v, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                elseif v:IsA("ImageButton") or v:IsA("ImageLabel") then
                    data[v].ImageTransparency = v.ImageTransparency
                    TweenService:Create(v, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
                end
                task.delay(0.5, function()
                    v.Visible = false
                    for i, x in next, data[v] do
                        v[i] = x
                    end
                end)
            end)
        end
    end
    return function()
        for i, _ in next, data do
            spawn(function()
                local properties = {
                    BackgroundTransparency = i.BackgroundTransparency
                }
                i.BackgroundTransparency = 1
                TweenService:Create(i, TweenInfo.new(0.5), {BackgroundTransparency = properties.BackgroundTransparency}):Play()
                if i:IsA("TextBox") or i:IsA("TextButton") or i:IsA("TextLabel") then
                    properties.TextTransparency = i.TextTransparency
                    i.TextTransparency = 1
                    TweenService:Create(i, TweenInfo.new(0.5), {TextTransparency = properties.TextTransparency}):Play()
                elseif i:IsA("ImageButton") or i:IsA("ImageLabel") then
                    properties.ImageTransparency = i.ImageTransparency
                    i.ImageTransparency = 1
                    TweenService:Create(i, TweenInfo.new(0.5), {ImageTransparency = properties.ImageTransparency}):Play()
                end
                i.Visible = true
            end)
        end
    end
end

local function maximizeSize(speed)
    if not speed then speed = 0.05 end
    TweenService:Create(LeftPanel, TweenInfo.new(speed), {Size = UDim2.fromOffset(LeftPanel.AbsoluteSize.X, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(RightPanel, TweenInfo.new(speed), {Size = UDim2.fromOffset(Background.AbsoluteSize.X - LeftPanel.AbsoluteSize.X, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(TopBar, TweenInfo.new(speed), {Size = UDim2.fromOffset(Background.AbsoluteSize.X, TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(ScrollingFrame, TweenInfo.new(speed), {Size = UDim2.fromOffset(Background.AbsoluteSize.X - LeftPanel.AbsoluteSize.X, 110), Position = UDim2.fromOffset(0, Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(CodeBox, TweenInfo.new(speed), {Size = UDim2.fromOffset(Background.AbsoluteSize.X - LeftPanel.AbsoluteSize.X, Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(LogList, TweenInfo.new(speed), {Size = UDim2.fromOffset(LogList.AbsoluteSize.X, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y - 18)}):Play()
end

local function minimizeSize(speed)
    if not speed then speed = 0.05 end
    TweenService:Create(LeftPanel, TweenInfo.new(speed), {Size = UDim2.fromOffset(LeftPanel.AbsoluteSize.X, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(RightPanel, TweenInfo.new(speed), {Size = UDim2.fromOffset(0, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(TopBar, TweenInfo.new(speed), {Size = UDim2.fromOffset(LeftPanel.AbsoluteSize.X, TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(ScrollingFrame, TweenInfo.new(speed), {Size = UDim2.fromOffset(0, 119), Position = UDim2.fromOffset(0, Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(CodeBox, TweenInfo.new(speed), {Size = UDim2.fromOffset(0, Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y)}):Play()
    TweenService:Create(LogList, TweenInfo.new(speed), {Size = UDim2.fromOffset(LogList.AbsoluteSize.X, Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y - 18)}):Play()
end

local function toggleMinimize(override)
    if mainClosing and not override or maximized then return end
    mainClosing = true
    closed = not closed
    if closed then
        if not sideClosed then
            gui_logic.toggleSideTray(true)
        end
        LeftPanel.Visible = true
        remotesFadeIn = fadeOut(LeftPanel:GetDescendants())
        TweenService:Create(LeftPanel, TweenInfo.new(0.5), {Size = UDim2.new(0, 131, 0, 0)}):Play()
        task.wait(0.5)
    else
        TweenService:Create(LeftPanel, TweenInfo.new(0.5), {Size = UDim2.new(0, 131, 0, 249)}):Play()
        task.wait(0.5)
        if remotesFadeIn then
            remotesFadeIn()
            remotesFadeIn = nil
        end
        gui_logic.bringBackOnResize()
    end
    mainClosing = false
end

local function toggleSideTray(override)
    if sideClosing and not override or maximized then return end
    sideClosing = true
    sideClosed = not sideClosed
    if sideClosed then
        rightFadeIn = fadeOut(RightPanel:GetDescendants())
        task.wait(0.5)
        minimizeSize(0.5)
        task.wait(0.5)
        RightPanel.Visible = false
    else
        if closed then
            toggleMinimize(true)
        end
        RightPanel.Visible = true
        maximizeSize(0.5)
        task.wait(0.5)
        if rightFadeIn then
            rightFadeIn()
        end
        gui_logic.bringBackOnResize()
    end
    sideClosing = false
end

local function toggleMaximize()
    if not sideClosed and not maximized then
        maximized = true
        local disable = Instance.new("TextButton")
        local prevSize = UDim2.new(0, CodeBox.AbsoluteSize.X, 0, CodeBox.AbsoluteSize.Y)
        local prevPos = UDim2.new(0, CodeBox.AbsolutePosition.X, 0, CodeBox.AbsolutePosition.Y)
        disable.Size = UDim2.new(1, 0, 1, 0)
        disable.BackgroundColor3 = Color3.new()
        disable.BorderSizePixel = 0
        disable.Text = 0
        disable.ZIndex = 3
        disable.BackgroundTransparency = 1
        disable.AutoButtonColor = false
        CodeBox.ZIndex = 4
        CodeBox.Position = prevPos
        CodeBox.Size = prevSize
        TweenService:Create(CodeBox, TweenInfo.new(0.5), {Size = UDim2.new(0.5, 0, 0.5, 0), Position = UDim2.new(0.25, 0, 0.25, 0)}):Play()
        TweenService:Create(disable, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
        disable.MouseButton1Click:Connect(function()
            if UserInputService:GetMouseLocation().Y + GuiInset.Y >= CodeBox.AbsolutePosition.Y and UserInputService:GetMouseLocation().Y + GuiInset.Y <= CodeBox.AbsolutePosition.Y + CodeBox.AbsoluteSize.Y and UserInputService:GetMouseLocation().X >= CodeBox.AbsolutePosition.X and UserInputService:GetMouseLocation().X <= CodeBox.AbsolutePosition.X + CodeBox.AbsoluteSize.X then
                return
            end
            TweenService:Create(CodeBox, TweenInfo.new(0.5), {Size = prevSize, Position = prevPos}):Play()
            TweenService:Create(disable, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            task.wait(0.5)
            disable:Destroy()
            CodeBox.Size = UDim2.new(1, 0, 0.5, 0)
            CodeBox.Position = UDim2.new(0, 0, 0, 0)
            CodeBox.ZIndex = 0
            maximized = false
        end)
    end
end

local function isInResizeRange(p)
    local relativeP = p - Background.AbsolutePosition
    local range = 5
    if relativeP.X >= TopBar.AbsoluteSize.X - range and relativeP.Y >= Background.AbsoluteSize.Y - range and relativeP.X <= TopBar.AbsoluteSize.X and relativeP.Y <= Background.AbsoluteSize.Y then
        return true, 'B'
    elseif relativeP.X >= TopBar.AbsoluteSize.X - range and relativeP.X <= Background.AbsoluteSize.X then
        return true, 'X'
    elseif relativeP.Y >= Background.AbsoluteSize.Y - range and relativeP.Y <= Background.AbsoluteSize.Y then
        return true, 'Y'
    end
    return false
end

local function isInDragRange(p)
    local relativeP = p - Background.AbsolutePosition
    local topbarAS = TopBar.AbsoluteSize
    return relativeP.X <= topbarAS.X - CloseButton.AbsoluteSize.X * 3 and relativeP.X >= 0 and relativeP.Y <= topbarAS.Y and relativeP.Y >= 0
end

local customCursor = Instance.new("ImageLabel")
customCursor.Visible = false
customCursor.Size = UDim2.fromOffset(200, 200)
customCursor.ZIndex = 1e9
customCursor.BackgroundTransparency = 1
customCursor.Image = ""
customCursor.Parent = SimpleSpy3

local function mouseEntered()
    local con = connections["SIMPLESPY_CURSOR"]
    if con then con:Disconnect() connections["SIMPLESPY_CURSOR"] = nil end
    connections["SIMPLESPY_CURSOR"] = RunService.RenderStepped:Connect(function()
        if not SimpleSpy3 or not SimpleSpy3.Parent or not SimpleSpy3.Enabled or closed or mainClosing then
            UserInputService.MouseIconEnabled = true
            customCursor.Visible = false
            return
        end
        UserInputService.MouseIconEnabled = not mouseInGui
        customCursor.Visible = mouseInGui
        if mouseInGui then
            local mouseLocation = UserInputService:GetMouseLocation() - GuiInset
            customCursor.Position = UDim2.fromOffset(mouseLocation.X - customCursor.AbsoluteSize.X / 2, mouseLocation.Y - customCursor.AbsoluteSize.Y / 2)
            local inRange, type = isInResizeRange(mouseLocation)
            if inRange and not closed then
                if not sideClosed then
                    customCursor.Image = type == 'B' and "rbxassetid://6065821980" or type == 'X' and "rbxassetid://6065821086" or type == 'Y' and "rbxassetid://6065821596"
                elseif type == 'Y' or type == 'B' then
                    customCursor.Image = "rbxassetid://6065821596"
                end
            elseif customCursor.Image ~= "rbxassetid://6065775281" then
                customCursor.Image = "rbxassetid://6065775281"
            end
        end
    end)
end

local function mouseMoved()
    local mousePos = UserInputService:GetMouseLocation() - GuiInset
    if not closed and mousePos.X >= TopBar.AbsolutePosition.X and mousePos.X <= TopBar.AbsolutePosition.X + TopBar.AbsoluteSize.X and mousePos.Y >= Background.AbsolutePosition.Y and mousePos.Y <= Background.AbsolutePosition.Y + Background.AbsoluteSize.Y then
        if not mouseInGui then
            mouseInGui = true
            mouseEntered()
        end
    else
        mouseInGui = false
    end
end

local function validateSize()
    local x, y = Background.AbsoluteSize.X, Background.AbsoluteSize.Y
    local screenSize = workspace.CurrentCamera.ViewportSize
    if x + Background.AbsolutePosition.X > screenSize.X then
        if screenSize.X - Background.AbsolutePosition.X >= 450 then
            x = screenSize.X - Background.AbsolutePosition.X
        else
            x = 450
        end
    elseif y + Background.AbsolutePosition.Y > screenSize.Y then
        if screenSize.Y - Background.AbsolutePosition.Y >= 268 then
            y = screenSize.Y - Background.AbsolutePosition.Y
        else
            y = 268
        end
    end
    Background.Size = UDim2.fromOffset(x, y)
end

local function bringBackOnResize()
    validateSize()
    if sideClosed then
        minimizeSize()
    else
        maximizeSize()
    end
    local currentX = Background.AbsolutePosition.X
    local currentY = Background.AbsolutePosition.Y
    local viewportSize = workspace.CurrentCamera.ViewportSize
    if currentX < 0 or currentX > viewportSize.X - (sideClosed and 131 or Background.AbsoluteSize.X) then
        currentX = math.clamp(currentX, 0, viewportSize.X - (sideClosed and 131 or Background.AbsoluteSize.X))
    end
    if currentY < 0 or currentY > viewportSize.Y - (closed and 19 or Background.AbsoluteSize.Y) - GuiInset.Y then
        currentY = math.clamp(currentY, 0, viewportSize.Y - (closed and 19 or Background.AbsoluteSize.Y) - GuiInset.Y)
    end
    TweenService:Create(Background, TweenInfo.new(0.1), {Position = UDim2.new(0, currentX, 0, currentY)}):Play()
end

local function connectResize()
    if not workspace.CurrentCamera then workspace:GetPropertyChangedSignal("CurrentCamera"):Wait() end
    local lastCam = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(bringBackOnResize)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        lastCam:Disconnect()
        lastCam = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(bringBackOnResize)
    end)
end

local function onBarInput(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local lastPos = input.Position
        local mainPos = Background.AbsolutePosition
        local offset = mainPos - Vector2.new(lastPos.X, lastPos.Y)
        local currentPos = offset + Vector2.new(lastPos.X, lastPos.Y)

        local dragConn
        dragConn = RunService.RenderStepped:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragConn:Disconnect()
                return
            end
            local newPos = input.Position
            if newPos ~= lastPos then
                local currentX = (offset + Vector2.new(newPos.X, newPos.Y)).X
                local currentY = (offset + Vector2.new(newPos.X, newPos.Y)).Y
                local viewportSize = workspace.CurrentCamera.ViewportSize
                currentX = math.clamp(currentX, 0, viewportSize.X - (sideClosed and 131 or TopBar.AbsoluteSize.X))
                currentY = math.clamp(currentY, 0, viewportSize.Y - (closed and 19 or Background.AbsoluteSize.Y) - GuiInset.Y)
                currentPos = Vector2.new(currentX, currentY)
                lastPos = newPos
                TweenService:Create(Background, TweenInfo.new(0.1), {Position = UDim2.new(0, currentPos.X, 0, currentPos.Y)}):Play()
            end
        end)

        local endedConn
        endedConn = UserInputService.InputEnded:Connect(function(inputE)
            if input == inputE then
                dragConn:Disconnect()
                endedConn:Disconnect()
            end
        end)
    end
end

local function backgroundUserInput(input)
    local mousePos = UserInputService:GetMouseLocation() - GuiInset
    local inResizeRange, type = isInResizeRange(mousePos)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if inResizeRange then
            local lastPos = input.Position
            local offset = Background.AbsoluteSize - Vector2.new(lastPos.X, lastPos.Y)
            local currentPos = lastPos + offset

            local resizeConn
            resizeConn = RunService.RenderStepped:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizeConn:Disconnect()
                    return
                end
                local newPos = input.Position
                if newPos ~= lastPos then
                    local currentX = (newPos + offset).X
                    local currentY = (newPos + offset).Y
                    currentX = math.max(450, currentX)
                    currentY = math.max(268, currentY)
                    currentPos = Vector2.new(currentX, currentY)
                    Background.Size = UDim2.fromOffset((not sideClosed and not closed and (type == "X" or type == "B")) and currentPos.X or Background.AbsoluteSize.X, (not closed and (type == "Y" or type == "B")) and currentPos.Y or Background.AbsoluteSize.Y)
                    validateSize()
                    if sideClosed then minimizeSize() else maximizeSize() end
                    lastPos = newPos
                end
            end)

            local endedConn
            endedConn = UserInputService.InputEnded:Connect(function(inputE)
                if input == inputE then
                    resizeConn:Disconnect()
                    endedConn:Disconnect()
                end
            end)
        elseif isInDragRange(mousePos) then
            onBarInput(input)
        end
    end
end

local function scaleToolTip()
    local size = TextService:GetTextSize(TextLabel.Text, TextLabel.TextSize, TextLabel.Font, Vector2.new(196, math.huge))
    TextLabel.Size = UDim2.new(0, size.X, 0, size.Y)
    ToolTip.Size = UDim2.new(0, size.X + 4, 0, size.Y + 4)
end

local function makeToolTip(enable, text)
    if enable and text then
        if ToolTip.Visible then
            ToolTip.Visible = false
            if connections["ToolTip"] then connections["ToolTip"]:Disconnect() end
        end
        local first = true
        connections["ToolTip"] = RunService.RenderStepped:Connect(function()
            local MousePos = UserInputService:GetMouseLocation()
            local topLeft = MousePos + Vector2.new(20, -15)
            local bottomRight = topLeft + ToolTip.AbsoluteSize
            local ViewportSize = workspace.CurrentCamera.ViewportSize
            if topLeft.X < 0 then topLeft = Vector2.new(0, topLeft.Y) end
            if bottomRight.X > ViewportSize.X then topLeft = Vector2.new(ViewportSize.X - ToolTip.AbsoluteSize.X, topLeft.Y) end
            if topLeft.Y < 0 then topLeft = Vector2.new(topLeft.X, 0) end
            if bottomRight.Y > ViewportSize.Y - 35 then topLeft = Vector2.new(topLeft.X, ViewportSize.Y - ToolTip.AbsoluteSize.Y - 35) end
            if topLeft.X <= MousePos.X and topLeft.Y <= MousePos.Y then
                topLeft = Vector2.new(MousePos.X - ToolTip.AbsoluteSize.X - 2, MousePos.Y - ToolTip.AbsoluteSize.Y - 2)
            end
            if first then
                ToolTip.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
                first = false
            else
                ToolTip:TweenPosition(UDim2.fromOffset(topLeft.X, topLeft.Y), "Out", "Linear", 0.1)
            end
        end)
        TextLabel.Text = text
        TextLabel.TextScaled = true
        ToolTip.Visible = true
    else
        if ToolTip.Visible then
            ToolTip.Visible = false
            if connections["ToolTip"] then connections["ToolTip"]:Disconnect() end
        end
    end
end

gui_logic.toggleMinimize    = toggleMinimize
gui_logic.toggleSideTray    = toggleSideTray
gui_logic.toggleMaximize    = toggleMaximize
gui_logic.bringBackOnResize = bringBackOnResize
gui_logic.connectResize     = connectResize
gui_logic.backgroundUserInput = backgroundUserInput
gui_logic.mouseEntered      = mouseEntered
gui_logic.mouseMoved        = mouseMoved
gui_logic.makeToolTip       = makeToolTip
gui_logic.scaleToolTip      = scaleToolTip
gui_logic.mouseInGui        = mouseInGui
gui_logic.closed            = closed
gui_logic.sideClosed        = sideClosed
gui_logic.maximized         = maximized
gui_logic.connections       = connections

return gui_logic
