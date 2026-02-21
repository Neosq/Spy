-- init.lua

if getgenv().SimpleSpyExecuted then
    if getgenv().SimpleSpyShutdown and type(getgenv().SimpleSpyShutdown) == "function" then
        getgenv().SimpleSpyShutdown()
    end
    for _, obj in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if obj.Name == "SimpleSpy" or obj.Name == "SimpleSpyIcon" then
            obj:Destroy()
        end
    end
    if gethui then
        for _, obj in ipairs(gethui():GetChildren()) do
            if obj.Name == "SimpleSpy" or obj.Name == "SimpleSpyIcon" then
                obj:Destroy()
            end
        end
    end
end

getgenv().SimpleSpyExecuted = true

-- Получаем модули из getgenv().SS (загружены loader-ом)
local SS             = getgenv().SS
local utils          = SS.utils
local gui_elements   = SS.gui_elements
local gui_logic      = SS.gui_logic
local remote_spy_core = SS.remote_spy_core
local serializer     = SS.serializer
local log_manager    = SS.log_manager
local buttons_addons = SS.buttons_addons

-- Загрузка конфига
local configs = {
    logcheckcaller = false,
    autoblock = false,
    funcEnabled = true,
    advancedinfo = false,
    supersecretdevtoggle = false
}

if isfile and readfile and isfolder and makefolder and writefile then
    xpcall(function()
        if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
        if not isfolder("SimpleSpy/Assets") then makefolder("SimpleSpy/Assets") end

        local path = "SimpleSpy/Settings.json"
        if isfile(path) then
            local data = game:GetService("HttpService"):JSONDecode(readfile(path))
            for k, v in pairs(configs) do
                if data[k] ~= nil then
                    configs[k] = data[k]
                end
            end
        end

        setmetatable(configs, {
            __newindex = function(t, k, v)
                rawset(t, k, v)
                writefile(path, game:GetService("HttpService"):JSONEncode(t))
            end
        })
    end, function(err)
        warn("Config save/load error: " .. tostring(err))
    end)
end

-- Highlight грузим отдельно (внешняя зависимость)
local Highlight = loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/Highlight.lua"))()

local SimpleSpy3     = gui_elements.SimpleSpy3
local Background     = gui_elements.Background
local TopBar         = gui_elements.TopBar
local Simple         = gui_elements.Simple
local CloseButton    = gui_elements.CloseButton
local MaximizeButton = gui_elements.MaximizeButton
local MinimizeButton = gui_elements.MinimizeButton
local ToolTip        = gui_elements.ToolTip
local TextLabel      = gui_elements.TextLabel
local Icon           = gui_elements.Icon

local LeftPanel      = gui_elements.LeftPanel
local LogList        = gui_elements.LogList
local RightPanel     = gui_elements.RightPanel
local CodeBox        = gui_elements.CodeBox
local ScrollingFrame = gui_elements.ScrollingFrame

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local codebox = Highlight.new(CodeBox)
log_manager.codebox = codebox  -- передаём codebox в log_manager

spawn(function()
    local suc, err = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/78n/SimpleSpy/main/UpdateLog.lua")
    codebox:setRaw(suc and err or "")
end)

gui_logic.connectResize()
gui_logic.bringBackOnResize()

Simple.MouseButton1Click:Connect(remote_spy_core.toggleSpy)

Simple.MouseEnter:Connect(function()
    if not remote_spy_core.toggle then
        TweenService:Create(Simple, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(252, 51, 51)}):Play()
    else
        TweenService:Create(Simple, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(68, 206, 91)}):Play()
    end
end)

Simple.MouseLeave:Connect(function()
    TweenService:Create(Simple, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(37, 36, 38)}):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    if Icon then Icon:Destroy() end
    getgenv().SimpleSpyShutdown()
end)

MinimizeButton.MouseButton1Click:Connect(gui_logic.toggleMinimize)
MaximizeButton.MouseButton1Click:Connect(gui_logic.toggleSideTray)

UserInputService.InputBegan:Connect(gui_logic.backgroundUserInput)

Background.MouseEnter:Connect(function()
    gui_logic.mouseInGui = true
    gui_logic.mouseEntered()
end)

Background.MouseLeave:Connect(function()
    gui_logic.mouseInGui = false
end)

UserInputService.InputChanged:Connect(gui_logic.mouseMoved)

gui_logic.makeToolTip(false)

-- Планировщик задач
local scheduled = {}

local function taskscheduler()
    if not remote_spy_core.toggle then
        scheduled = {}
        return
    end
    if #scheduled > 0 then
        local task = table.remove(scheduled, 1)
        if type(task) == "table" and type(task[1]) == "function" then
            pcall(unpack(task))
        end
    end
end

local schedulerconnect = RunService.Heartbeat:Connect(taskscheduler)

remote_spy_core.toggleSpy()
buttons_addons.create()

getgenv().SimpleSpyShutdown = function()
    if schedulerconnect then schedulerconnect:Disconnect() end
    for _, connection in next, gui_logic.connections do
        connection:Disconnect()
    end
    SimpleSpy3:Destroy()
    gui_elements.Storage:Destroy()
    UserInputService.MouseIconEnabled = true
    getgenv().SimpleSpyExecuted = false
end

task.delay(1, function()
    gui_logic.toggleMinimize()
end)
