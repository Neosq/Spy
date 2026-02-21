local log_manager = {}

-- Зависимости
local SS           = getgenv().SS
local gui_elements = SS.gui_elements
local gui_logic    = SS.gui_logic
local serializer   = SS.serializer

local LogList        = gui_elements.LogList
local ScrollingFrame = gui_elements.ScrollingFrame

-- UIListLayout и UIGridLayout берём из детей фреймов
local UIListLayout = LogList:FindFirstChildOfClass("UIListLayout")
local UIGridLayout = ScrollingFrame:FindFirstChildOfClass("UIGridLayout")

local TweenService = game:GetService("TweenService")

local layoutOrderNum = 999999999
local logs       = {}
local remoteLogs = {}
local selected   = nil
local blacklist  = {}
local blocklist  = {}
local history    = {}
local excluding  = {}
local DecompiledScripts = {}
local codebox    = nil  -- будет установлен из init.lua через log_manager.codebox = ...

local OldDebugId = typeof(game.HttpService) ~= "nil" and function(i)
    return game:GetService("HttpService"):GenerateGUID(false)
end or function() return "" end

-- Переопределяем нормальный debugid если доступен
if game and game.GetService then
    local ok, svc = pcall(function() return game:GetService("HttpService") end)
end
-- используем стандартный если есть
OldDebugId = (typeof(tostring) == "function") and function(instance)
    if typeof(instance) == "Instance" then
        return tostring(instance):match("%((.-)%)") or tostring(instance)
    end
    return tostring(instance)
end or OldDebugId

local function logthread(thread)
    -- заглушка, реализация в remote_spy_core
end

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
    if UIListLayout then
        LogList.CanvasSize = UDim2.fromOffset(UIListLayout.AbsoluteContentSize.X, UIListLayout.AbsoluteContentSize.Y)
    end
end

local function updateFunctionCanvas()
    if UIGridLayout then
        ScrollingFrame.CanvasSize = UDim2.fromOffset(UIGridLayout.AbsoluteContentSize.X, UIGridLayout.AbsoluteContentSize.Y)
    end
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
        if codebox then
            codebox:setRaw(selected.GenScript)
        end
    end
    if gui_logic.sideClosed then
        gui_logic.toggleSideTray()
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
        log.GenScript = serializer.genScript(log.Remote, log.args)
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

-- Экспорт
log_manager.newRemote           = newRemote
log_manager.clean               = clean
log_manager.updateRemoteCanvas  = updateRemoteCanvas
log_manager.updateFunctionCanvas = updateFunctionCanvas
log_manager.eventSelect         = eventSelect
log_manager.logthread           = logthread
log_manager.logs                = logs
log_manager.remoteLogs          = remoteLogs
log_manager.selected            = selected
log_manager.blacklist           = blacklist
log_manager.blocklist           = blocklist
log_manager.history             = history
log_manager.excluding           = excluding
log_manager.DecompiledScripts   = DecompiledScripts
log_manager.OldDebugId          = OldDebugId
-- codebox устанавливается снаружи после инициализации Highlight:
-- log_manager.codebox = codebox

return log_manager
