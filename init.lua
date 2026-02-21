-- init.lua

-- Если уже запущен — выключаем старую версию
if getgenv().SimpleSpyShutdown and type(getgenv().SimpleSpyShutdown) == "function" then
    pcall(getgenv().SimpleSpyShutdown)
end
getgenv().SimpleSpyExecuted = true

-- Получаем модули из getgenv().SS (загружены loader-ом)
local SS              = getgenv().SS
local utils           = SS.utils
local gui_elements    = SS.gui_elements
local gui_logic       = SS.gui_logic
local remote_spy_core = SS.remote_spy_core
local serializer      = SS.serializer
local log_manager     = SS.log_manager
local buttons_addons  = SS.buttons_addons

-- Загрузка конфига
local configs = {
    logcheckcaller       = false,
    autoblock            = false,
    funcEnabled          = true,
    advancedinfo         = false,
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
                if data[k] ~= nil then configs[k] = data[k] end
            end
        end

        setmetatable(configs, {
            __newindex = function(t, k, v)
                rawset(t, k, v)
                if writefile then
                    writefile(path, game:GetService("HttpService"):JSONEncode(t))
                end
            end
        })
    end, function(err)
        warn("Config save/load error: " .. tostring(err))
    end)
end

-- Сохраняем configs в SS чтобы другие модули (remote_spy_core, buttons_addons) могли его получить
getgenv().SS.configs = configs

-- Highlight
local Highlight = loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/Highlight.lua"))()

local SimpleSpy3     = gui_elements.SimpleSpy3
local Background     = gui_elements.Background
local TopBar         = gui_elements.TopBar
local Simple         = gui_elements.Simple
local CloseButton    = gui_elements.CloseButton
local MaximizeButton = gui_elements.MaximizeButton
local MinimizeButton = gui_elements.MinimizeButton
local Icon           = gui_elements.Icon
local CodeBox        = gui_elements.CodeBox
local ScrollingFrame = gui_elements.ScrollingFrame
local LogList        = gui_elements.LogList
local LeftPanel      = gui_elements.LeftPanel
local RightPanel     = gui_elements.RightPanel

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local codebox = Highlight.new(CodeBox)
log_manager.codebox = codebox

spawn(function()
    local suc, res = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/78n/SimpleSpy/main/UpdateLog.lua")
    codebox:setRaw(suc and res or "")
end)

gui_logic.connectResize()
gui_logic.bringBackOnResize()

-- SimpleSpy toggle кнопка (вкл/выкл шпион)
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

-- X кнопка — уничтожает GUI и иконку
CloseButton.MouseButton1Click:Connect(function()
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

-- Иконка — скрыть/показать GUI
local guiVisible = true
Icon.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    SimpleSpy3.Enabled = guiVisible
end)

-- Планировщик задач
local schedulerconnect = RunService.Heartbeat:Connect(function()
    -- пустой планировщик, schedule в remote_spy_core теперь использует task.spawn
end)

remote_spy_core.toggleSpy()
buttons_addons.create(configs)

-- Функция завершения (должна быть объявлена ДО использования в CloseButton)
getgenv().SimpleSpyShutdown = function()
    pcall(function()
        if schedulerconnect then schedulerconnect:Disconnect() end
        -- Отключаем хуки
        if remote_spy_core.toggle then
            pcall(remote_spy_core.disablehooks)
        end
        -- Отключаем все соединения gui_logic
        for _, connection in next, gui_logic.connections do
            pcall(function() connection:Disconnect() end)
        end
        -- Уничтожаем GUI и иконку
        if SimpleSpy3 and SimpleSpy3.Parent then SimpleSpy3:Destroy() end
        if Icon and Icon.Parent then Icon:Destroy() end
        if gui_elements.Storage and gui_elements.Storage.Parent then
            gui_elements.Storage:Destroy()
        end
        UserInputService.MouseIconEnabled = true
        getgenv().SimpleSpyExecuted = false
        getgenv().SS = nil
    end)
end

task.delay(1, function()
    gui_logic.toggleMinimize()
end)
