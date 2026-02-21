local log_manager = {}

local layoutOrderNum = 999999999
local logs = {}
local remoteLogs = {}
local selected = nil

local function clean()
    local max = getgenv().SIMPLESPYCONFIG_MaxRemotes or 500
    if #remoteLogs > max then
        for i = 100, #remoteLogs do
            local v = remoteLogs[i]
            if typeof(v[1]) == "RBXScriptConnection" then
                v[1]:Disconnect()
            end
            if typeof(v[2]) == "Instance" then
                v[2]:Destroy()
            end
        end
        local newLogs = {}
        for i = 1, 100 do
            table.insert(newLogs, remoteLogs[i])
        end
        remoteLogs = newLogs
    end
end

local function updateRemoteCanvas()
    LogList.CanvasSize = UDim2.fromOffset(UIListLayout.AbsoluteContentSize.X, UIListLayout.AbsoluteContentSize.Y)
end

local function updateFunctionCanvas()
    ScrollingFrame.CanvasSize = UDim2.fromOffset(UIGridLayout.AbsoluteContentSize.X, UIGridLayout.AbsoluteContentSize.Y)
end

local function eventSelect(frame)
    if selected and selected.Log then
        if selected.Button then
            spawn(function()
                TweenService:Create(selected.Button, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
            end)
        end
        selected = nil
    end
    for _, v in next, logs do
        if frame == v.Log then
            selected = v
        end
    end
    if selected and selected.Log then
        spawn(function()
            TweenService:Create(frame.Button, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(92, 126, 229)}):Play()
        end)
        codebox:setRaw(selected.GenScript)
    end
    if sideClosed then
        toggleSideTray()
    end
end

local function newRemote(type, data)
    if layoutOrderNum < 1 then layoutOrderNum = 999999999 end
    local remote = data.remote
    local callingscript = data.callingscript

    local RemoteTemplate = Instance.new("Frame")
    RemoteTemplate.LayoutOrder = layoutOrderNum
    RemoteTemplate.Name = "RemoteTemplate"
    RemoteTemplate.Parent = LogList
    RemoteTemplate.BackgroundColor3 = Color3.new(1, 1, 1)
    RemoteTemplate.BackgroundTransparency = 1
    RemoteTemplate.Size = UDim2.new(0, 117, 0, 27)

    local ColorBar = Instance.new("Frame")
    ColorBar.Name = "ColorBar"
    ColorBar.Parent = RemoteTemplate
    ColorBar.BackgroundColor3 = (type == "event" and Color3.fromRGB(255, 242, 0)) or Color3.fromRGB(99, 86, 245)
    ColorBar.BorderSizePixel = 0
    ColorBar.Position = UDim2.new(0, 0, 0, 1)
    ColorBar.Size = UDim2.new(0, 7, 0, 18)
    ColorBar.ZIndex = 2

    local Text = Instance.new("TextLabel")
    Text.TextTruncate = Enum.TextTruncate.AtEnd
    Text.Name = "Text"
    Text.Parent = RemoteTemplate
    Text.BackgroundColor3 = Color3.new(1, 1, 1)
    Text.BackgroundTransparency = 1
    Text.Position = UDim2.new(0, 12, 0, 1)
    Text.Size = UDim2.new(0, 105, 0, 18)
    Text.ZIndex = 2
    Text.Font = Enum.Font.SourceSans
    Text.Text = remote.Name
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.TextSize = 14
    Text.TextXAlignment = Enum.TextXAlignment.Left

    local Button = Instance.new("TextButton")
    Button.Name = "Button"
    Button.Parent = RemoteTemplate
    Button.BackgroundColor3 = Color3.new(0, 0, 0)
    Button.BackgroundTransparency = 0.75
    Button.BorderColor3 = Color3.new(1, 1, 1)
    Button.Position = UDim2.new(0, 0, 0, 1)
    Button.Size = UDim2.new(0, 117, 0, 18)
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.SourceSans
    Button.Text = ""
    Button.TextColor3 = Color3.new(0, 0, 0)
    Button.TextSize = 14

    local log = {
        Name = remote.Name,
        Function = data.infofunc or "--Function Info is disabled",
        Remote = remote,
        DebugId = data.id,
        metamethod = data.metamethod,
        args = data.args,
        Log = RemoteTemplate,
        Button = Button,
        Blocked = data.blocked,
        Source = callingscript,
        returnvalue = data.returnvalue,
        GenScript = "-- Generating, please wait...\n-- (If this message persists, the remote args are likely extremely long)"
    }

    logs[#logs + 1] = log

    local connect = Button.MouseButton1Click:Connect(function()
        logthread(coroutine.running())
        eventSelect(RemoteTemplate)
        log.GenScript = genScript(log.Remote, log.args)
        if data.blocked then
            log.GenScript = "-- THIS REMOTE WAS PREVENTED FROM FIRING TO THE SERVER BY SIMPLESPY\n\n" .. log.GenScript
        end
        if selected == log and RemoteTemplate then
            eventSelect(RemoteTemplate)
        end
    end)

    layoutOrderNum = layoutOrderNum - 1
    table.insert(remoteLogs, 1, {connect, RemoteTemplate})
    clean()
    updateRemoteCanvas()
end

log_manager.newRemote = newRemote
log_manager.clean = clean
log_manager.updateRemoteCanvas = updateRemoteCanvas
log_manager.updateFunctionCanvas = updateFunctionCanvas
log_manager.eventSelect = eventSelect
log_manager.logs = logs
log_manager.remoteLogs = remoteLogs
log_manager.selected = selected

return log_manager
